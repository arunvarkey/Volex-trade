# Privacy policy — superseded

The policy that ships is **[`store/privacy-policy.html`](../store/privacy-policy.html)**.
That is the file to host and to link from the Play Console.

This markdown version is kept only as a pointer, because the text it used to
contain described a different application and would have been wrong as a legal
document:

- **"We transmit trade intent to your connected exchange (e.g., Binance) to
  execute orders."** The app places no real orders and holds no exchange
  connection. A privacy policy that says otherwise tells a regulator the app
  does something it does not do.
- **"Your exchange API keys are stored with AES-256 encryption on your
  device."** The app no longer collects exchange keys at all; the screen that
  used to now offers to delete anything an earlier build saved.
- **"To provide AI-generated strategy recommendations."** There is no model
  and nothing is sent anywhere to be analysed.
- **"biometric data (stored locally via Secure Enclave)"** — the app lock uses
  the platform biometric prompt, which returns a yes/no. No biometric data is
  read, stored or transmitted by Volex.
- The contact line was still `[YOUR_CONTACT_EMAIL]`.

A privacy policy is the one document where over-claiming is worse than
under-claiming: it is a binding statement about data handling, and the Play
Data Safety form must agree with it. `store/privacy-policy.html` and
`store/data-safety.md` are written to match each other and the code.
