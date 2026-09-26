# Mail approval lives in skymail

Event “mail users” opens skymail with an Event / Gecekodu template. Recipients are club-wide lists (all Members) and separately managed Event mail lists (GECEKODU attendees vs AGC attendees). A User without send permission confirms the values; approvers get Mail onayı in skymail and, if they approve, the send proceeds. Core does not own the approval queue. Rejected: SMTP from superadmin; 403-on-write as the product; one global list as the only audience.
