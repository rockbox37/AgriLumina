import { assert, assertEquals } from "jsr:@std/assert@1";
import {
  contentHash,
  HIDE_THRESHOLD,
  normalizeBody,
  scorePost,
  SPAM_THRESHOLD,
  statusForScore,
} from "../_shared/spam.ts";
import { cleanText, isUuid, parsePostInput } from "../_shared/validation.ts";

const NO_BLOCKLIST = { isFirstPost: false, blocklist: [] };

Deno.test("normalizeBody lowercases, strips accents/punctuation, collapses space", () => {
  assertEquals(
    normalizeBody("  Prêt RAPIDE!!!   sans   garantie. "),
    "pret rapide sans garantie",
  );
});

Deno.test("contentHash is stable across cosmetic differences", async () => {
  const a = await contentHash("Maize for sale, near Bugobe!");
  const b = await contentHash("maize FOR sale near bugobe");
  assertEquals(a, b);
  const c = await contentHash("beans for sale near bugobe");
  assert(a !== c);
});

Deno.test("plain marketplace post scores visible", () => {
  const { score } = scorePost(
    "Selling 3 sacks of dried maize at Bugobe market this Saturday.",
    NO_BLOCKLIST,
  );
  assert(score < HIDE_THRESHOLD);
  assertEquals(statusForScore(score), "visible");
});

Deno.test("post sharing a phone number stays visible", () => {
  const { score } = scorePost(
    "Call me on +243 970 123 456 if you want fresh cassava.",
    NO_BLOCKLIST,
  );
  assert(score < HIDE_THRESHOLD, `score ${score}`);
});

Deno.test("multiple URLs get hidden", () => {
  const { score, signals } = scorePost(
    "Visit https://a.example http://b.example www.c.example now",
    NO_BLOCKLIST,
  );
  assert(score >= HIDE_THRESHOLD, `score ${score}`);
  assert(signals.includes("many_urls"));
});

Deno.test("first post containing a URL is penalized extra", () => {
  const seasoned = scorePost("see https://example.com", NO_BLOCKLIST);
  const first = scorePost("see https://example.com", {
    isFirstPost: true,
    blocklist: [],
  });
  assertEquals(first.score, seasoned.score + 2);
});

Deno.test("shouting long post accumulates caps signal", () => {
  const { signals } = scorePost(
    "BUY NOW AMAZING OFFER LIMITED TIME DO NOT MISS THIS DEAL",
    NO_BLOCKLIST,
  );
  assert(signals.includes("caps"));
});

Deno.test("blocklist terms match against normalized body", () => {
  const { score, signals } = scorePost(
    "Prêt rapide, sans garantie — contactez-nous!",
    {
      isFirstPost: false,
      blocklist: [{ term: "pret rapide sans garantie", weight: 4 }],
    },
  );
  assertEquals(score, 4);
  assert(signals.some((s) => s.startsWith("blocklist:")));
});

Deno.test("scam post with URL and blocklist term is marked spam", () => {
  const { score } = scorePost(
    "DOUBLE YOUR MONEY GUARANTEED!!! Visit https://scam.example and https://scam2.example NOW",
    {
      isFirstPost: true,
      blocklist: [
        { term: "double your money", weight: 5 },
        { term: "guaranteed", weight: 2 },
      ],
    },
  );
  assert(score >= SPAM_THRESHOLD, `score ${score}`);
  assertEquals(statusForScore(score), "spam");
});

Deno.test("statusForScore thresholds", () => {
  assertEquals(statusForScore(HIDE_THRESHOLD - 1), "visible");
  assertEquals(statusForScore(HIDE_THRESHOLD), "hidden");
  assertEquals(statusForScore(SPAM_THRESHOLD), "spam");
});

Deno.test("cleanText strips control characters but keeps newlines", () => {
  assertEquals(cleanText("hello\u0000\u0007 world\nline2"), "hello world\nline2");
});

Deno.test("isUuid accepts v4 uuids and rejects junk", () => {
  assert(isUuid("a3bb189e-8bf9-3888-9912-ace4e6543002"));
  assert(!isUuid("not-a-uuid"));
  assert(!isUuid(42));
});

Deno.test("parsePostInput validates and normalizes", () => {
  const parsed = parsePostInput({
    device_id: "A3BB189E-8BF9-3888-9912-ACE4E6543002",
    author_name: "  Amani  ",
    body: "Selling maize",
  });
  assert(parsed.ok);
  assertEquals(parsed.value.deviceId, "a3bb189e-8bf9-3888-9912-ace4e6543002");
  assertEquals(parsed.value.authorName, "Amani");
  assertEquals(parsed.value.parentId, null);

  assert(!parsePostInput({ device_id: "x", author_name: "A", body: "hi" }).ok);
  assert(
    !parsePostInput({
      device_id: "a3bb189e-8bf9-3888-9912-ace4e6543002",
      author_name: "A",
      body: "x",
    }).ok,
  );
});
