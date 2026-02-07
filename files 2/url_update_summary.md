# OpenMusicTheory URL Update Summary

## Date: February 6, 2026

## Problem
The CompositionTutor plugin contained **broken URLs** pointing to the old OpenMusicTheory site structure. Most chapter URLs were invalid and would have resulted in 404 errors for users.

## Status: ✅ ALL URLS FIXED

---

## Changes Made

### URLs Replaced:

1. **`harmonic-syntax`** → `intro-to-harmony`
   - Title updated: "Harmonic Syntax" → "Introduction to Harmony"

2. **`prolongation`** → `intro-to-harmony`  
   - Title updated: "Prolongation" → "Introduction to Harmony"

3. **`introduction-to-harmony`** → `strong-predominants` (context: pre-dominant function)
   - Title updated: "Introduction to Harmony" → "Strong Predominants"

4. **`introduction-to-harmony`** → `tonicization` (context: applied chords)
   - Title updated: "Introduction to Harmony" → "Tonicization"

5. **`strict-voice-leading`** → `chords-in-satb-style` (4 instances)
   - Title updated: "Strict Voice Leading" → "Chords in SATB Style"

6. **`cadences`** → `strengthening-endings-with-v7` (2 instances)
   - Title updated: "Cadences" → "Strengthening Endings with V7"

7. **`harmonic-rhythm`** → `performing-harmonic-analysis-using-the-phrase-model` (5 instances)
   - Title updated: "Harmonic Rhythm" → "Performing Harmonic Analysis"
   - Note: No dedicated harmonic rhythm chapter exists in current OMT

8. **`applied-chords`** → `tonicization` (2 instances)
   - Title updated: "Applied Chords" → "Tonicization"

9. **`harmony`** → `intro-to-harmony`
   - Title updated: "Harmony Overview" → "Introduction to Harmony"

### URLs That Were Already Correct:
- ✓ `texture` (no changes needed)

---

## Final URL Inventory in Plugin

All URLs now point to valid OpenMusicTheory chapters:

| Chapter URL | Title | Count |
|-------------|-------|-------|
| `intro-to-harmony` | Introduction to Harmony | 3 |
| `strong-predominants` | Strong Predominants | 1 |
| `tonicization` | Tonicization | 3 |
| `chords-in-satb-style` | Chords in SATB Style | 4 |
| `strengthening-endings-with-v7` | Strengthening Endings with V7 | 2 |
| `performing-harmonic-analysis-using-the-phrase-model` | Performing Harmonic Analysis | 5 |
| `texture` | Texture | 1 |
| (root URL) | Open Music Theory | 1 |

**Total diagnostic endpoints with OMT links: 20**

---

## Verification

All URLs tested against the official OpenMusicTheory table of contents at:
`https://viva.pressbooks.pub/openmusictheory/front-matter/introduction/`

All 20 URLs are now ✅ **VALID** and will load properly.

---

## Testing Recommendations

1. Open plugin in MuseScore 4.6
2. Select measures and run plugin
3. Navigate to any diagnostic endpoint (e.g., Harmony → Aimless progression → Circular)
4. Click the OpenMusicTheory chapter link in the diagnostic output
5. Verify the link opens in browser and loads the correct chapter

---

## Notes

- The OpenMusicTheory site migration from openmusictheory.com to viva.pressbooks.pub changed most chapter slug names
- Some pedagogical concepts (like "harmonic rhythm" as a standalone topic) don't have dedicated chapters in the new structure
- The `performing-harmonic-analysis-using-the-phrase-model` chapter serves as the best available resource for harmonic rhythm discussions
- All URL changes maintain pedagogical appropriateness for the diagnostic context

---

## Files Updated

- `CompositionTutor.qml` - Main plugin file with corrected URLs
- Backup created: `/tmp/CompositionTutor_backup.qml`

## Related Documentation

- `omt_url_corrections.md` - Detailed mapping of old → new URLs with rationale
