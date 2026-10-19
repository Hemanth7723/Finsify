# API and Integration Specification - Expensify

## 1. Gemini Endpoint

The source calls:

```text
POST https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key={apiKey}
```

The client uses a 60-second connect, read, and write timeout.

## 2. Request Envelope

```json
{
  "contents": [{"parts": [{"text": "prompt"}]}],
  "systemInstruction": {"parts": [{"text": "instruction"}]},
  "generationConfig": {
    "responseMimeType": "application/json",
    "temperature": 0.1
  }
}
```

`systemInstruction` and `generationConfig` are optional at the DTO level. Voice parsing supplies JSON response type and low temperature. Insights supply a higher temperature and do not request JSON.

## 3. Response Shape Used

```json
{
  "candidates": [
    {"content": {"parts": [{"text": "response text"}]}}
  ]
}
```

The client uses the first candidate and first text part. Missing candidates or text produce an empty-result error state.

## 4. Voice Parsing Contract

The model must return a raw JSON object with exactly these logical fields:

```json
{
  "title": "Short purchase name",
  "amount": 0.0,
  "category": "Food",
  "note": "Optional context"
}
```

Allowed categories are `Food`, `Transport`, `Entertainment`, `Shopping`, `Health`, `Utilities`, and `Miscellaneous`. The current Kotlin client defensively extracts the first `{` through the last `}` and applies defaults: `Voice Expense`, `0.0`, `Miscellaneous`, and an empty note.

## 5. Insights Contract

The prompt contains at most the latest 30 expenses with date, category, currency symbol, amount, title, and note. The response is markdown text organized into:

1. Financial Persona Profile
2. Expenditure Critique
3. Smart Behavioral Upgrades

The Flutter client must render untrusted model output as text/markdown safely and must not interpret it as executable content.

## 6. Error Handling

| Condition | Required behavior |
| --- | --- |
| Missing/placeholder API key | Do not call network; show profile/API-key guidance |
| Timeout or transport error | Preserve local data; show retryable AI error |
| Empty candidates/text | Show no-result error |
| Invalid voice JSON | Apply safe defaults only when parsing succeeds; otherwise show parsing error |
| HTTP/API rejection | Show a user-safe error; do not expose the API key |

## 7. Credential Storage

The user-provided key is stored through the platform secure-storage abstraction. Build-time fallback configuration must be supplied through a local, excluded environment mechanism and must never be committed.