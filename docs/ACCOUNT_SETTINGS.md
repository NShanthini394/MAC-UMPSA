# Account settings v0.15

Account actions are grouped under Settings → Account. The marked raw UID and
instruction paragraphs are removed, as is the automatic-save footer. Account
ID remains available through a copy button. The page scrolls on phones.

Guest username and avatar are stored in a profile keyed by the local Guest ID.
Signed-in names are saved to Firebase Authentication's displayName and the
local account profile. Avatars are the ten bundled character portraits and are
stored per account on this device; photo upload/cloud avatar sync is not added.

Local guests have no Firebase UID. Creating an email account or linking Google
preserves their local profile under the resulting Firebase UID. This is not
cloud save synchronization. An existing permanent profile is not overwritten.
The auth service also supports linking an already-authenticated Firebase
anonymous user with signUp + idToken, retaining that UID.

Email changes reauthenticate, then request VERIFY_AND_CHANGE_EMAIL. The primary
email remains unchanged until the new inbox verification link is confirmed.
Refresh Account Information retrieves the confirmed server value. Password
changes also reauthenticate. Google sessions prompt again through the existing
Android Credential Manager bridge and reject a different Firebase UID.
These operations edit the game account; they do not rename a Gmail address or
change the Google account password. An email/password credential can be added
to a Google game account while preserving its Firebase UID.

Permanent deletion requires typing DELETE, then entering the current password
or confirming the same Google identity. Only after accounts:delete succeeds
are the in-memory session and this device's stored profile removed. Failed
reauthentication/deletion leaves the identity and profile intact. No admin
credentials are used. No production account was created or deleted in tests.
Sensitive edits are disabled while in a room. Avatar selection remains local.

Validation: mocked Firebase identity/update/link/delete flows; wrong-provider
UID rejection; malformed-response checks; cancellation; guest profile migration
and other-account isolation. UI forms verified at 1280×720, 2340×1080, 1920×1200.
Live Firebase email delivery and physical Android Google prompts require user
testing. This client-only release uses the existing protocol-6 Render service.

Sources used:
https://firebase.google.com/docs/reference/rest/auth
https://docs.cloud.google.com/identity-platform/docs/admin/email-enumeration-protection
https://identitytoolkit.googleapis.com/$discovery/rest?version=v1
