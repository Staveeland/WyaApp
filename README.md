# Wya

This project demonstrates a simple location sharing app. Invites are handled using CloudKit shares and Universal Links to mimic Apple's native location sharing flow.

## Backend Setup
1. **CloudKit Container**: In your Apple Developer account, create a CloudKit container named `iCloud.com.example.Wya`. Update the bundle ID and container identifier to match your app.
2. **Associated Domains**: Configure an associated domain for universal links (e.g. `applinks:example.com`) in your Apple Developer portal and in `Wya.entitlements`.
3. **Universal Link Hosting**: Host the Apple App Site Association (AASA) file on your domain to enable Universal Links.
4. **Production Schema**: If you plan to test with TestFlight, make sure to deploy the CloudKit schema to the production environment so the app can access your records when distributed.

No additional backend servers are required; CloudKit handles sharing and data storage.
