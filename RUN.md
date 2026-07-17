# Running GentleWake on your iPhone (no Xcode, free Apple ID)

Two ways to see the app. The first needs nothing but a browser; the second
puts it on your actual iPhone.

## A. Tap through it in a browser (instant, zero install)

1. GitHub → this repo → **Actions** → latest **"Build runnable app"** run.
2. Download the **`GentleWake-sim-app`** artifact and unzip it.
3. Go to **appetize.io**, make a free account, and drag `GentleWake.app`
   (inside the zip) onto the upload area.
4. It runs in the browser — this is the **full** app (Health/Home/widget
   included), driven with your mouse.

## B. Install on your iPhone with Sideloadly (this Mac + free Apple ID)

This installs the **Lite** build — the whole gradual-wake experience (dial,
fade-in alarm, background audio, sounds, sleep mode, ringing, notification
backup, local sleep tracking). Health, HomeKit, and the Dynamic Island
widget are left out because a free Apple ID can't sign them.

**Heads-up:** free-signed apps stop opening after **7 days**. Just re-run
Sideloadly to refresh for another week.

1. **Get the app file.** GitHub → **Actions** → latest **"Build runnable
   app"** run → download the **`GentleWake-Lite-ipa`** artifact. Unzip it;
   inside is `GentleWake-Lite-unsigned.ipa`.
2. **Install Sideloadly.** Download from **sideloadly.io**, open the `.dmg`,
   drag Sideloadly to Applications. (No Xcode, no account needed to install
   it.)
3. **Plug your iPhone into this Mac** with a cable. On the phone, tap
   **Trust** if it asks about trusting this computer.
4. **Open Sideloadly.** It should show your iPhone at the top. Drag
   `GentleWake-Lite-unsigned.ipa` into the Sideloadly window.
5. **Enter your Apple ID** in the Apple account field. A normal, free Apple
   ID is fine. (If it has two-factor on, Sideloadly will ask for an
   app-specific password — it links you to where to make one. If your main
   Apple ID gives trouble, making a fresh free Apple ID just for this works.)
6. Click **Start**. Sideloadly signs and installs the app. First run can
   take a couple of minutes.
7. **Trust the app on your iPhone:** Settings → General → **VPN & Device
   Management** → tap your Apple ID email → **Trust**.
8. Launch **GentleWake** from your home screen.

### Testing the alarm for real
- Set a wake time a few minutes out, drag the moon handle so the fade window
  is short, and toggle **Alarm on**.
- Leave the app foregrounded (or just locked) — the sound fades in from
  silence. If iOS suspends the app, the backup **notification** still fires
  at wake time. That three-layer behavior is the whole point of the app, and
  it's the part only a real device can fully prove.

## Rebuilding locally (if you ever get Xcode on a Mac)

    xcodegen generate
    open GentleWake.xcodeproj   # then press Run

`GentleWake` = full app. `GentleWakeLite` = the trimmed sideload build.
