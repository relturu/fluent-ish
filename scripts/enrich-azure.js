#!/usr/bin/env node

const fs = require("node:fs/promises");
const path = require("node:path");

const API_VERSION = "3.0";
const DEFAULT_ENDPOINT = "https://api.cognitive.microsofttranslator.com";
const REQUEST_TIMEOUT_MS = 30_000;

function parseDotEnv(contents) {
  const values = {};

  for (const line of contents.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;

    const match = trimmed.match(/^(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/);
    if (!match) continue;

    let value = match[2].trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    } else {
      value = value.replace(/\s+#.*$/, "").trim();
    }
    values[match[1]] = value;
  }

  return values;
}

async function loadEnvironment(envPath) {
  let fileValues = {};
  try {
    fileValues = parseDotEnv(await fs.readFile(envPath, "utf8"));
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
  }

  const environment = { ...fileValues, ...process.env };
  const missing = ["AZURE_KEY", "AZURE_REGION"].filter(
    (name) => !environment[name]?.trim(),
  );
  if (missing.length > 0) {
    throw new Error(
      `Missing required Azure environment variable(s): ${missing.join(", ")}. ` +
        `Set them in the environment or ${envPath}.`,
    );
  }

  const endpoint = environment.AZURE_ENDPOINT || DEFAULT_ENDPOINT;
  let endpointURL;
  try {
    endpointURL = new URL(endpoint);
  } catch {
    throw new Error("AZURE_ENDPOINT must be a valid HTTPS base URL.");
  }
  if (
    endpointURL.protocol !== "https:" ||
    endpointURL.username ||
    endpointURL.password ||
    endpointURL.search ||
    endpointURL.hash
  ) {
    throw new Error(
      "AZURE_ENDPOINT must be an HTTPS base URL without credentials, query, or fragment.",
    );
  }

  return {
    key: environment.AZURE_KEY,
    region: environment.AZURE_REGION,
    endpoint: endpointURL,
  };
}

function parseArguments(argv) {
  const options = {
    seedDir: path.resolve(__dirname, "../firebase/seed"),
    wordsFile: null,
    promptsFile: null,
    envFile: path.resolve(__dirname, ".env"),
    help: false,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (argument === "--help" || argument === "-h") {
      options.help = true;
      continue;
    }

    const optionNames = {
      "--seed-dir": "seedDir",
      "--words": "wordsFile",
      "--prompts": "promptsFile",
      "--env-file": "envFile",
    };
    const optionName = optionNames[argument];
    if (!optionName) throw new Error(`Unknown option: ${argument}`);
    const value = argv[index + 1];
    if (!value || value.startsWith("--")) {
      throw new Error(`Expected a path after ${argument}.`);
    }
    options[optionName] = path.resolve(value);
    index += 1;
  }

  if (!options.wordsFile) options.wordsFile = path.join(options.seedDir, "words.json");
  if (!options.promptsFile) {
    options.promptsFile = path.join(options.seedDir, "dailyPrompts.json");
  }
  return options;
}

function printUsage() {
  console.log(`Usage: node scripts/enrich-azure.js [options]

Enrich words.json and dailyPrompts.json in firebase/seed with Azure Translator.

Options:
  --seed-dir PATH   Seed directory (default: firebase/seed)
  --words PATH      Words seed JSON (default: <seed-dir>/words.json)
  --prompts PATH    Daily prompts seed JSON (default: <seed-dir>/dailyPrompts.json)
  --env-file PATH   Gitignored env file (default: scripts/.env)
  --help, -h        Show this help

Required credentials: AZURE_KEY and AZURE_REGION. AZURE_ENDPOINT is optional.`);
}

async function readRecords(filePath, label) {
  let document;
  try {
    document = JSON.parse(await fs.readFile(filePath, "utf8"));
  } catch (error) {
    if (error.code === "ENOENT") {
      throw new Error(`${label} seed file not found: ${filePath}`);
    }
    if (error instanceof SyntaxError) {
      throw new Error(`${label} seed file is not valid JSON: ${filePath}`);
    }
    throw error;
  }

  const original = JSON.parse(JSON.stringify(document));
  if (Array.isArray(document)) {
    return {
      original,
      records: document,
      replace: (records) => records,
    };
  }

  if (document && typeof document === "object") {
    const property = label === "Words" ? "words" : "dailyPrompts";
    if (Array.isArray(document[property])) {
      return {
        original,
        records: document[property],
        replace: (records) => ({ ...document, [property]: records }),
      };
    }
  }

  throw new Error(
    `${label} seed must be a JSON array or an object containing the expected array.`,
  );
}

async function saveIfChanged(filePath, original, records, replace) {
  const updated = replace(records);
  if (JSON.stringify(updated) === JSON.stringify(original)) return false;
  const serialized = `${JSON.stringify(updated, null, 2)}\n`;
  await fs.writeFile(filePath, serialized, "utf8");
  return true;
}

function hasText(value) {
  return typeof value === "string" && value.trim().length > 0;
}

class AzureTranslator {
  constructor(configuration) {
    this.configuration = configuration;
  }

  async post(endpointPath, parameters, body) {
    const url = new URL(this.configuration.endpoint);
    url.pathname = `${url.pathname.replace(/\/+$/, "")}${endpointPath}`;
    url.searchParams.set("api-version", API_VERSION);
    for (const [name, value] of Object.entries(parameters)) {
      url.searchParams.set(name, value);
    }

    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Ocp-Apim-Subscription-Key": this.configuration.key,
        "Ocp-Apim-Subscription-Region": this.configuration.region,
        "Content-Type": "application/json; charset=UTF-8",
      },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
    });

    const responseText = await response.text();
    let responseJSON;
    try {
      responseJSON = JSON.parse(responseText);
    } catch {
      throw new Error(
        `Azure ${endpointPath} returned HTTP ${response.status} with an invalid JSON response.`,
      );
    }

    if (!response.ok) {
      const apiMessage =
        responseJSON?.error?.message || responseJSON?.error?.code || "";
      const requestId = response.headers.get("x-requestid");
      const details = [
        `Azure ${endpointPath} returned HTTP ${response.status}`,
        requestId ? `(request ID ${requestId})` : "",
        apiMessage ? `: ${apiMessage}` : "",
      ]
        .filter(Boolean)
        .join(" ");
      throw new Error(details);
    }

    if (!Array.isArray(responseJSON)) {
      throw new Error(`Azure ${endpointPath} returned an unexpected JSON shape.`);
    }
    return responseJSON;
  }

  lookup(text, from, to) {
    return this.post(
      "/dictionary/lookup",
      { from, to },
      [{ Text: text }],
    );
  }

  examples(text, translation, from, to) {
    return this.post(
      "/dictionary/examples",
      { from, to },
      [{ Text: text, Translation: translation }],
    );
  }

  translate(text, from, to) {
    return this.post("/translate", { from, to }, [{ Text: text }]);
  }
}

async function enrichWord(word, translator, fetchedAt) {
  if (word.azure && Array.isArray(word.azure.translations)) {
    return { changed: false, message: "cached Azure lookup" };
  }

  const sourceText = hasText(word.lemma) ? word.lemma.trim() : word.term?.trim();
  if (!sourceText) {
    return { changed: false, message: "skipped: missing lemma and term" };
  }

  const language = word.language || "es";
  const lookupResults = await translator.lookup(sourceText, language, "en");
  const lookup = lookupResults[0];
  const translations = Array.isArray(lookup?.translations)
    ? lookup.translations
    : [];

  word.azure = {
    translations: translations.map((translation) => translation.displayTarget),
    fetchedAt,
  };

  const best = translations.reduce(
    (current, candidate) =>
      !current || candidate.confidence > current.confidence ? candidate : current,
    null,
  );

  if (best?.normalizedTarget && (!hasText(word.example) || !hasText(word.exampleEn))) {
    const exampleResults = await translator.examples(
      lookup.normalizedSource || sourceText,
      best.normalizedTarget,
      language,
      "en",
    );
    const example = exampleResults[0]?.examples?.find(
      (candidate) =>
        hasText(candidate.sourcePrefix) ||
        hasText(candidate.sourceTerm) ||
        hasText(candidate.sourceSuffix),
    );

    if (example) {
      const sourceSentence =
        `${example.sourcePrefix}${example.sourceTerm}${example.sourceSuffix}`.trim();
      const targetSentence =
        `${example.targetPrefix}${example.targetTerm}${example.targetSuffix}`.trim();
      if (!hasText(word.example) && sourceSentence) {
      word.example = sourceSentence;
      if (!hasText(word.exampleEn) && targetSentence) {
        word.exampleEn = targetSentence;
      }
      } else if (
      hasText(word.example) &&
      !hasText(word.exampleEn) &&
      sourceSentence === word.example.trim() &&
      targetSentence
      ) {
      word.exampleEn = targetSentence;
      }
    }
  }

  return {
    changed: true,
    message: translations.length
      ? `looked up ${translations.length} translation(s)`
      : "lookup returned no translations",
  };
}

async function enrichPrompt(prompt, translator) {
  if (hasText(prompt.textEn)) return { changed: false, message: "already translated" };
  if (!hasText(prompt.text)) return { changed: false, message: "skipped: missing text" };

  const results = await translator.translate(
    prompt.text,
    prompt.language || "es",
    "en",
  );
  const translation = results[0]?.translations?.find(
    (candidate) => hasText(candidate.text),
  );
  if (!translation) {
    return { changed: false, message: "translation response was empty" };
  }

  prompt.textEn = translation.text;
  return { changed: true, message: "translated" };
}

async function main() {
  const options = parseArguments(process.argv.slice(2));
  if (options.help) {
    printUsage();
    return;
  }

  const configuration = await loadEnvironment(options.envFile);
  const translator = new AzureTranslator(configuration);
  const [wordsDocument, promptsDocument] = await Promise.all([
    readRecords(options.wordsFile, "Words"),
    readRecords(options.promptsFile, "Daily prompts"),
  ]);
  const fetchedAt = new Date().toISOString();
  let wordChanges = 0;
  let promptChanges = 0;

  for (const [index, word] of wordsDocument.records.entries()) {
    if (!word || typeof word !== "object" || Array.isArray(word)) {
      throw new Error(`Invalid word record at index ${index} in ${options.wordsFile}`);
    }
    const result = await enrichWord(word, translator, fetchedAt);
    if (result.changed) wordChanges += 1;
    console.log(`Word ${word.term || word.lemma || index}: ${result.message}`);
  }

  for (const [index, prompt] of promptsDocument.records.entries()) {
    if (!prompt || typeof prompt !== "object" || Array.isArray(prompt)) {
      throw new Error(
        `Invalid daily prompt record at index ${index} in ${options.promptsFile}`,
      );
    }
    const result = await enrichPrompt(prompt, translator);
    if (result.changed) promptChanges += 1;
    console.log(`Prompt ${prompt.date || index}: ${result.message}`);
  }

  const [wordsWritten, promptsWritten] = await Promise.all([
    saveIfChanged(
      options.wordsFile,
      wordsDocument.original,
      wordsDocument.records,
      wordsDocument.replace,
    ),
    saveIfChanged(
      options.promptsFile,
      promptsDocument.original,
      promptsDocument.records,
      promptsDocument.replace,
    ),
  ]);

  console.log(
    `Enrichment complete: ${wordChanges} word(s), ${promptChanges} prompt(s) enriched.`,
  );
  console.log(
    `Files ${wordsWritten ? "updated" : "unchanged"}: ${options.wordsFile}; ` +
      `${promptsWritten ? "updated" : "unchanged"}: ${options.promptsFile}`,
  );
}

main().catch((error) => {
  console.error(`Azure enrichment failed: ${error.message}`);
  process.exitCode = 1;
});
