# PAYI App — Complete Flow Diagrams

## 1. App Startup & Authentication Flow

```mermaid
flowchart TD
    A[App Launch] --> B[main.dart: runApp]
    B --> C[MultiProvider + WalletProvider]
    C --> D{Auth Mode}
    D -->|Production| E[AuthScreen: WebView]
    D -->|Prototype| F[DashboardSaaSScreen]
    E --> G[Load Clerk Auth Page]
    G --> H{Page Finished?}
    H -->|auth.html| I[Show Login Form]
    H -->|dashboard.html| J[Extract User Email via JS]
    I --> K[User Logs In via Clerk]
    K --> H
    J --> L{Email Valid?}
    L -->|Yes| M[Set ApiService.currentAuthEmail]
    L -->|No| N[Log Error, Stay on Auth]
    M --> F
    F --> O[WalletProvider.fetchData]
    O --> P{API Available?}
    P -->|Yes| Q[Fetch Wallet + Transactions from API]
    P -->|No| R[Load Mock Data Fallback]
    Q --> S[Render Dashboard]
    R --> S
```

---

## 2. Dashboard Navigation Map

```mermaid
flowchart TD
    DASH[Dashboard Screen] --> SEARCH[Search Bar → Search Contacts]
    DASH --> PROFILE[Profile Avatar → Profile Screen]
    DASH --> SCAN_BTN[Scan Pill → Scan QR Screen]
    DASH --> BAL_BTN[Balance Pill → Balance Details]

    DASH --> G1[Grid: Scan any QR → Scan QR Screen]
    DASH --> G2[Grid: Pay Contacts → Transfer Screen]
    DASH --> G3[Grid: Pay to Phone → Transfer Screen]
    DASH --> G4[Grid: Bank Transfer → Bank Transfer Screen]
    DASH --> G5[Grid: Pay Bills → Pay Bills Screen]
    DASH --> G6[Grid: Wallet Top-up → Top-up Screen]
    DASH --> G7[Grid: Receive Money → Receive Money Screen]
    DASH --> G8[Grid: Settings → Settings Screen]

    DASH --> PEOPLE[People Section]
    PEOPLE --> P_ALEX[Alex → Transfer Screen]
    PEOPLE --> P_SARAH[Sarah → Transfer Screen]
    PEOPLE --> P_MIKE[Mike → Transfer Screen]
    PEOPLE --> P_EMMA[Emma → Transfer Screen]
    PEOPLE --> P_TOPUP[Topup → Top-up Screen]

    DASH --> TX_LIST[Recent History]
    TX_LIST --> TX_DETAIL[Transaction Details Screen]
```

---

## 3. Send Money / Transfer Flow

```mermaid
flowchart TD
    A[Transfer Screen] --> B{Pre-filled Recipient?}
    B -->|Yes from Contact| C[Email field auto-filled]
    B -->|Yes from QR| C
    B -->|No| D[User types email/phone]
    C --> E[User enters amount in USD]
    D --> E
    E --> F[Tap Send Money]
    F --> G{Validate Input}
    G -->|Empty fields| H[Show error SnackBar]
    G -->|Invalid amount| H
    G -->|Valid| I[Set loading state]
    I --> J[ApiService.sendMoney]
    J --> K{API Response}
    K -->|Success 200| L[WalletProvider.fetchData refresh]
    L --> M[Show success SnackBar]
    M --> N[Navigator.pop → Dashboard]
    K -->|Error| O[Show error SnackBar]
    O --> P[Reset loading state]
```

---

## 4. QR Scan Flow

```mermaid
flowchart TD
    A[Scan QR Screen] --> B[Show Camera Placeholder]
    B --> C[Animate scan line up/down]
    C --> D[Wait 4 seconds - simulate scan]
    D --> E[Navigator.pushReplacement]
    E --> F[Transfer Screen]
    F --> G["Pre-filled: scanned-user@example.com"]
```

---

## 5. Bank Transfer Flow

```mermaid
flowchart TD
    A[Bank Transfer Screen] --> B[Display Saved Banks]
    B --> C1[Chase Bank *1234]
    B --> C2[Bank of America *5678]
    B --> C3[Wells Fargo *9012]
    B --> D[Add New Bank Account]
    C1 --> E[Enter Transfer Amount]
    C2 --> E
    C3 --> E
    D --> F[Enter Bank Name + Account #]
    F --> G[Save to List]
    G --> E
    E --> H[Tap Confirm Transfer]
    H --> I{Validate Amount}
    I -->|Valid| J[Deduct from Wallet]
    J --> K[Add Transaction Record]
    K --> L[Show Success SnackBar]
    L --> M[Pop to Dashboard]
    I -->|Invalid| N[Show Error SnackBar]
```

---

## 6. Wallet Top-up Flow

```mermaid
flowchart TD
    A[Top-up Screen] --> B[Enter Amount]
    B --> C[Select Funding Source]
    C --> D1["Visa *4242 (default)"]
    C --> D2[Chase Checking *1234]
    C --> D3[Add Payment Method]
    D1 --> E[Tap Confirm Top-up]
    D2 --> E
    D3 --> F[Show Add Method Dialog]
    F --> E
    E --> G{Validate Amount > 0?}
    G -->|Yes| H[WalletProvider.topUp]
    H --> I[Add balance to wallet]
    I --> J[Create receive transaction]
    J --> K[Show Success SnackBar]
    K --> L[Pop to Dashboard]
    G -->|No| M[Show Error SnackBar]
```

---

## 7. Pay Bills Flow

```mermaid
flowchart TD
    A[Pay Bills Screen] --> B[Display 6 Categories]
    B --> C1[Electricity]
    B --> C2[Water]
    B --> C3[Internet]
    B --> C4["TV & Cable"]
    B --> C5[Mobile Postpaid]
    B --> C6[Education]
    C1 --> D[Show Payment Dialog]
    C2 --> D
    C3 --> D
    C4 --> D
    C5 --> D
    C6 --> D
    D --> E[Enter Account # + Amount]
    E --> F[Tap Pay]
    F --> G{Validate Input}
    G -->|Valid| H[WalletProvider.payBill]
    H --> I[Deduct from wallet]
    I --> J[Add send transaction]
    J --> K[Show Success SnackBar]
    G -->|Invalid| L[Show Error SnackBar]
```

---

## 8. Receive Money Flow

```mermaid
flowchart TD
    A[Receive Money Screen] --> B[Display Personal QR Code]
    B --> C[Show payment link: payi.me/wallet]
    C --> D{User Action}
    D -->|Tap Copy Icon| E["Copy link to clipboard (SnackBar)"]
    D -->|Tap Share Button| F["Share link (SnackBar)"]
```

---

## 9. Profile & Settings Navigation

```mermaid
flowchart TD
    A[Profile Screen] --> B1[My Wallet → Balance Details Screen]
    A --> B2[My QR Code → Receive Money Screen]
    A --> B3[Security → Security Dialog]
    A --> B4["Help & Support → Help Dialog"]
    B3 --> C1[Change PIN]
    B3 --> C2[Toggle Biometrics]

    S[Settings Screen] --> S1[Dark Mode Toggle]
    S --> S2[Notifications → Preferences Dialog]
    S --> S3[Language → Language Picker]
    S --> S4[Privacy → Privacy Info Dialog]
    S --> S5[Billing → Top-up Screen]
    S --> S6[About PAYI → About Dialog]
    S --> S7[Log Out → Confirmation Dialog]
    S7 --> S8{Confirmed?}
    S8 -->|Yes| S9[Pop to root / Auth Screen]
    S8 -->|No| S10[Dismiss]
```

---

## 10. Data Layer Architecture

```mermaid
flowchart TD
    subgraph "Presentation"
        UI[Screens / Widgets]
    end

    subgraph "State Management"
        WP[WalletProvider - ChangeNotifier]
    end

    subgraph "Service Layer"
        API[ApiService]
    end

    subgraph "Data"
        M1[Wallet Model]
        M2[Transaction Model]
    end

    subgraph "Backend"
        BE["C# .NET API (192.168.1.158:5088)"]
    end

    UI -->|"context.watch / context.read"| WP
    WP -->|fetchData / topUp / payBill| API
    API -->|"HTTP GET/POST"| BE
    BE -->|JSON| API
    API -->|"parse"| M1
    API -->|"parse"| M2
    WP -->|"mock fallback"| M1
    WP -->|"mock fallback"| M2
    WP -->|notifyListeners| UI
```

---

## 11. Complete Screen Map

```mermaid
graph LR
    subgraph "Entry"
        AUTH[Auth Screen]
    end

    subgraph "Main"
        DASH[Dashboard]
    end

    subgraph "Money Operations"
        TRANSFER[Send Money]
        BANK[Bank Transfer]
        TOPUP[Wallet Top-up]
        RECEIVE[Receive Money]
        BILLS[Pay Bills]
        SCANQR[Scan QR]
    end

    subgraph "Account"
        PROFILE[Profile]
        SETTINGS[Settings]
        SEARCH[Search Contacts]
        BALANCE[Balance Details]
        TXDETAIL[Transaction Details]
    end

    AUTH -->|login| DASH
    DASH --> TRANSFER
    DASH --> BANK
    DASH --> TOPUP
    DASH --> RECEIVE
    DASH --> BILLS
    DASH --> SCANQR
    DASH --> PROFILE
    DASH --> SETTINGS
    DASH --> SEARCH
    DASH --> BALANCE
    DASH --> TXDETAIL
    SCANQR -->|auto| TRANSFER
    SEARCH -->|tap| TRANSFER
    PROFILE --> BALANCE
    PROFILE --> RECEIVE
    SETTINGS --> TOPUP
```
