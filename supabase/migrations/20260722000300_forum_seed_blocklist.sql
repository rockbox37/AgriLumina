-- Starter blocklist (en/fr). Terms are matched as substrings against the
-- normalized body: lowercased, diacritics stripped, punctuation removed,
-- whitespace collapsed — so entries here must be in that normalized form.
-- Weights add to the heuristic spam score (hidden at 5, spam at 10).

insert into forum_blocklist (term, weight) values
  -- get-rich / investment scams
  ('double your money', 5),
  ('doublez votre argent', 5),
  ('guaranteed profit', 4),
  ('profit garanti', 4),
  ('investment opportunity', 3),
  ('opportunite d investissement', 3),
  ('forex trading', 3),
  ('binary options', 4),
  ('options binaires', 4),
  ('bitcoin investment', 4),
  ('investissement bitcoin', 4),
  ('crypto giveaway', 5),
  -- loan / advance-fee fraud
  ('instant loan', 4),
  ('pret rapide sans garantie', 4),
  ('loan without collateral', 4),
  ('processing fee required', 4),
  ('frais de dossier requis', 4),
  -- prize / lottery scams
  ('you have won', 4),
  ('vous avez gagne', 4),
  ('claim your prize', 4),
  ('reclamez votre prix', 4),
  ('lottery winner', 4),
  -- generic spam markers
  ('work from home earn', 3),
  ('travail a domicile gagnez', 3),
  ('click this link to', 2),
  ('cliquez sur ce lien pour', 2),
  ('send money to', 3),
  ('envoyez de l argent a', 3);
