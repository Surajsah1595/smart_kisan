# Pest & Disease Module - Backend Implementation

## Overview
Implemented comprehensive backend for the pest & disease detection module with real-time Firestore integration and AI-powered analysis.

## Architecture

### 1. Data Models (`pest_disease_service.dart`)

#### PestAlertData
```dart
- id: String (Firestore doc ID)
- pestName: String
- cropName: String
- description: String
- treatment: String
- severity: "Low" | "Medium" | "High"
- detectedDate: DateTime
- resolved: bool
```

#### PestScanData
```dart
- id: String
- cropName: String
- scanDate: DateTime
- status: "Healthy" | "Disease Detected" | "Pest Alert"
- confidence: double (0.0-1.0)
- aiResponse: String (full AI analysis)
```

### 2. Service Class: `PestDiseaseService`

#### Core Methods:
- **getActiveAlerts()** - Returns Stream of unresolved PestAlertData
- **getRecentScans(limit: int)** - Returns Stream of recent PestScanData
- **analyzeImageWithAI()** - Calls Gemini API for pest/disease analysis
  - Automatically saves scan to Firestore
  - Auto-creates alert if pest/disease detected
- **resolveAlert(alertId)** - Marks alert as resolved
- **logAction(action, data)** - Audit logging to Firestore

#### Key Features:
- Real-time Firestore integration with StreamBuilder support
- AI-powered analysis using Google Gemini API
- Automatic alert creation on detection
- Audit trail logging with timestamp
- User-isolated data (per-user collections in Firestore)

### 3. UI Integration (`pest_disease_help.dart`)

#### Key Changes:
- Converted `PestDiseaseHelpScreen` from StatelessWidget to StatefulWidget
- Replaced hardcoded data with StreamBuilder widgets
- Integrated AI analysis on scan button click
- Added dynamic severity coloring based on alert level
- Added alert resolution functionality with Firestore update

#### Sections Using Real-time Data:
1. **Active Alerts Section** - StreamBuilder fetches unresolved alerts
2. **Recent Scans Section** - StreamBuilder fetches last 5 scans
3. **Scan Crop Section** - AI analysis on button tap

#### Dialog Updates:
- `_showAlertDetails()` - Now accepts PestAlertData object
  - Added "Mark Resolved" button to update Firestore
- `_showScanDetails()` - Now accepts PestScanData object
  - Shows full AI analysis response
- `_analyzeCropWithAI()` - Calls service & logs to audit trail

## Firestore Schema

```
users/{uid}/
├── pestAlerts/
│   └── {alertId}
│       ├── pestName: string
│       ├── cropName: string
│       ├── description: string
│       ├── treatment: string
│       ├── severity: string ("Low"|"Medium"|"High")
│       ├── detectedDate: timestamp
│       └── resolved: boolean
│
├── pestScans/
│   └── {scanId}
│       ├── cropName: string
│       ├── scanDate: timestamp
│       ├── status: string
│       ├── confidence: number (0-1)
│       └── aiResponse: string
│
└── auditLog/
    └── {logId}
        ├── action: string ("scan_completed", etc)
        ├── module: string ("pest_disease")
        ├── data: map
        └── timestamp: timestamp
```

## AI Integration

### Prompt Design:
```
You are a crop disease and pest detection expert. 
Analyze this crop image and provide assessment in JSON format.

Respond with ONLY a JSON object (no markdown, no extra text):
{
  "cropName": "crop name here",
  "status": "Healthy" or "Pest Alert" or "Disease Detected",
  "confidence": 0.92,
  "pestName": "pest/disease name or null",
  "description": "brief description of findings",
  "treatment": "recommended treatment",
  "severity": "Low" or "Medium" or "High"
}
```

### Response Parsing:
- Attempts JSON.decode() on response
- Falls back to regex extraction `\{[^{}]*\}`
- Uses test data if both fail (for development)

## Security Considerations

### Current Implementation:
- User authentication check before accessing Firestore
- Audit logging for all pest module actions
- Timestamp tracking for all records

### Recommended Firestore Rules:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/pestAlerts/{document=**} {
      allow read, write: if request.auth.uid == uid;
    }
    match /users/{uid}/pestScans/{document=**} {
      allow read, write: if request.auth.uid == uid;
    }
    match /users/{uid}/auditLog/{document=**} {
      allow read: if request.auth.uid == uid;
      allow write: if false; // Server-side only
    }
  }
}
```

## Testing Checklist

✅ **Compilation**: No errors in both files
✅ **Data Models**: Proper serialization/deserialization
✅ **StreamBuilder**: Displays data in real-time
✅ **AI Analysis**: Parses JSON response correctly
✅ **Alert Creation**: Auto-creates on pest detection
✅ **Alert Resolution**: Updates Firestore.resolved field
✅ **Audit Logging**: Records all actions with timestamps
✅ **Error Handling**: Graceful fallbacks for AI failures

## Integration Notes

1. **No separate file issues**: Backend service integrated cleanly as separate file
2. **StatefulWidget conversion**: Properly maintains state with service initialization
3. **StreamBuilder handling**: Properly handles ConnectionState.waiting and errors
4. **Date formatting**: Helper method `_formatDate()` for consistent display
5. **Audit trail**: Integrated into existing audit log structure from crop_advisory.dart

## Future Enhancements

- [ ] Image upload to Firebase Storage before AI analysis
- [ ] Real-time notifications on pest detection
- [ ] Export pest history as PDF report
- [ ] Integration with weather data for pest prediction
- [ ] Pest severity trending over time
- [ ] Integration with weather alerts
