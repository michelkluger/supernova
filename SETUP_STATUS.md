# Setup Status

## ✅ Done by automation

| Component | Where |
|---|---|
| **VS Code Monkey C extension** v1.1.3 | Installed via `code --install-extension garmin.monkey-c` |
| **OpenSSL Light** v4.0.0 | `C:\Program Files\OpenSSL-Win64\bin\openssl.exe` (via winget) |
| **JDK 17 (Temurin)** | `C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot` |
| **`JAVA_HOME` + PATH** | Set to user-level environment |
| **Developer key (RSA 4096, PKCS8 DER)** | `C:\Users\miche\.garmin\developer_key.der` |
| **VS Code Monkey C settings** | `monkeyC.developerKeyPath` wired to the dev key |
| **SDK Manager (downloaded + extracted)** | `C:\Users\miche\.garmin\sdk-manager\sdkmanager.exe` |

## ⚠️ Remaining — requires you (5–10 min)

The actual SDK + Edge 1030+ device profile downloads happen *inside* the SDK Manager GUI and require logging into a Garmin developer account. I can't do that piece.

### Step-by-step

**1. Launch the SDK Manager**
```
C:\Users\miche\.garmin\sdk-manager\sdkmanager.exe
```
(Or from PowerShell: `& "$env:USERPROFILE\.garmin\sdk-manager\sdkmanager.exe"`)

**2. Sign in or create a Garmin developer account** (free) — uses your existing Garmin Connect login if you have one.

**3. Inside the SDK Manager:**
- **SDKs tab** → install the **latest stable SDK** (currently 7.x)
- **Devices tab** → search for **Edge 1030 Plus** → install the device profile + simulator
- Optional: also install the **Edge 1040** profile if you want to target that later

**4. Open the project in VS Code**
```
code C:\Users\miche\garmin\edge-datafield
```

**5. First build**
- `Ctrl+Shift+P` → **Monkey C: Build for Device**
- If it asks to select a target device → pick **Edge 1030 Plus**
- Output: `bin\EdgeDataFieldApp.prg`

**6. Run in simulator**
- `Ctrl+Shift+P` → **Monkey C: Run No Live Review** → pick Edge 1030 Plus
- The simulator opens. Use **File → Simulate Activity** → pick a `.fit` file (or use the built-in simulated cycling activity) to feed live data into the data field.

## Once it builds…

Send me whatever the compiler complains about. There are usually 3-5 small SDK API differences to reconcile (this code targets Connect IQ 3.2+; minor adjustments common per SDK version).

## Sideload to the actual Edge 1030+

Once the simulator works:
1. Build → `bin\EdgeDataFieldApp.prg`
2. Plug Edge 1030+ in via USB
3. Copy `EdgeDataFieldApp.prg` → `GARMIN\APPS\` on the device
4. Disconnect, restart device
5. **Activity Profile → Data Screens → Add Page → Single Field → Connect IQ → Edge 1030+ DataField**
6. Configure FTP/Max HR/LTHR/Weight via the Garmin Connect IQ companion app on phone
