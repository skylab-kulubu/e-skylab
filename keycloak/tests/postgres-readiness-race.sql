-- Keep the entrypoint's temporary initialization server observable long enough
-- for the fresh-runner fixture to prove that pg_isready alone is insufficient.
SELECT pg_sleep(4);
