# HTTP is the resource plus RFC 7807 errors

Go APIs return the resource as JSON with HTTP status as the outcome (200/201/204). Errors use RFC 7807 problem+json (`title`, `status`, `detail`, `instance`). The Java `DataResult` envelope (`success`, `message`, `data`) is not preserved. This matches cms-backend today and common public API practice; superadmin will be rewritten against it.
