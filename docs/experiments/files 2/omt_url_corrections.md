# OpenMusicTheory URL Corrections for CompositionTutor Plugin

## Current Status: Most URLs in Plugin are BROKEN ❌

The original OpenMusicTheory site (openmusictheory.com) has been migrated to a new platform at viva.pressbooks.pub, and the chapter URLs have changed significantly.

## URL Corrections Needed

### ❌ BROKEN URLs Currently in Plugin:

1. **harmonic-syntax** → Does not exist
   - **Suggested replacement:** `performing-harmonic-analysis-using-the-phrase-model`
   - **Alternative:** `intro-to-harmony` (for basic harmonic function concepts)

2. **prolongation** → Does not exist  
   - **Suggested replacement:** `64-chords-as-prolongations`
   - **Note:** This is very specific to 6/4 chords, may not be ideal

3. **introduction-to-harmony** → Does not exist
   - **Correct URL:** `intro-to-harmony` (note the abbreviated "intro")

4. **strict-voice-leading** → Does not exist
   - **Suggested replacement:** `chords-in-satb-style` (practical voice leading)
   - **Alternative:** `first-species-counterpoint` (if teaching strict rules)

5. **cadences** → Does not exist
   - **Suggested replacement:** `strengthening-endings-with-v7` (cadential formulas)
   - **Alternative:** `performing-harmonic-analysis-using-the-phrase-model` (includes cadence discussion)

6. **harmonic-rhythm** → Does not exist
   - **No direct equivalent found**
   - **Alternatives:** 
     - `performing-harmonic-analysis-using-the-phrase-model` (mentions harmonic considerations)
     - `intro-to-harmony` (may discuss harmonic rhythm)

7. **applied-chords** → Does not exist
   - **Correct URL:** `tonicization` (covers applied/secondary chords)
   - **Alternative:** `extended-tonicization-and-modulation-to-closely-related-keys`

8. **harmony** → Does not exist (too generic)
   - **Correct URL:** `intro-to-harmony`

### ✓ VALID URLs:
- `texture` ✓ (works correctly)

---

## Recommended URL Mapping for Plugin Diagnostics

Based on the diagnostic categories in the plugin, here are the best chapter matches:

### **HARMONY DIAGNOSTICS:**

#### Aimless Progression → Circular/Meandering
```
omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/intro-to-harmony/"
Alternative: "https://viva.pressbooks.pub/openmusictheory/chapter/performing-harmonic-analysis-using-the-phrase-model/"
```

#### Aimless Progression → Weak Tonic
```
omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/intro-to-harmony/"
Alternative: "https://viva.pressbooks.pub/openmusictheory/chapter/fragile-absent-and-emergent-tonics/" (advanced)
```

#### Aimless Progression → Missing Pre-dominant
```
omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/strong-predominants/"
```

#### Voice Leading → Parallels/Leaps/Doublings/Crossing
```
omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/chords-in-satb-style/"
```

#### Weak Arrival → Weak Predominant
```
omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/strong-predominants/"
```

#### Weak Arrival → Cadential Issues
```
omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/strengthening-endings-with-v7/"
Alternative: "https://viva.pressbooks.pub/openmusictheory/chapter/cadential-64/"
```

#### Too Predictable → Applied Chords/Chromaticism
```
omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/tonicization/"
```

#### Harmonic Rhythm Issues
```
omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/performing-harmonic-analysis-using-the-phrase-model/"
Note: No dedicated harmonic rhythm chapter exists
```

---

## Complete List of Available Harmony-Related Chapters

### Core Harmony Concepts:
- `intro-to-harmony` - Introduction to Harmony
- `roman-numerals` - Roman Numerals  
- `figured-bass` - Figured Bass
- `triads` - Triads
- `seventh-chords` - Seventh Chords
- `inversion` - Inversion

### Harmonic Function:
- `performing-harmonic-analysis-using-the-phrase-model` - Performing Harmonic Analysis
- `strong-predominants` - Strong Predominants
- `strengthening-endings-with-v7` - Strengthening Endings with V7
- `plagal-motion` - Plagal Motion
- `leading-tone-chord` - Leading Tone Chord
- `the-mediant` - The Mediant
- `predominant-seventh-chords` - Predominant Seventh Chords

### Voice Leading:
- `chords-in-satb-style` - Chords in SATB Style
- `inverted-v7s` - Inverted V7s
- `cadential-64` - Cadential 6/4
- `64-chords-as-prolongations` - 6/4 Chords as Prolongations
- `la-in-the-bass` - La in the Bass

### Embellishment:
- `embellishing-tones` - Embellishing Tones

### Sequences:
- `diatonic-sequences` - Diatonic Sequences
- `chromatic-sequences` - Chromatic Sequences

### Chromaticism:
- `tonicization` - Tonicization
- `extended-tonicization-and-modulation-to-closely-related-keys` - Extended Tonicization
- `modal-mixture` - Modal Mixture
- `augmented-sixth-chords` - Augmented Sixth Chords
- `bii6` - bII6 (Neapolitan)
- `common-tone-chords` - Common Tone Chords

### Advanced:
- `harmonic-elision` - Harmonic Elision
- `mediants` - Mediants
- `neo-riemannian-triadic-progressions` - Neo-Riemannian Progressions

### Form (may be relevant for proportion/balance diagnostics):
- `formal-sections-in-general` - Formal Sections
- `phrase-archetypes-unique-forms` - Phrase Archetypes
- `binary-form` - Binary Form
- `ternary-form` - Ternary Form
- `sonata-form` - Sonata Form

---

## Action Items:

1. ✅ Replace all broken URLs in plugin
2. ⚠️ Consider adding fallback to general `intro-to-harmony` for topics without specific chapters
3. 📝 Note: Some pedagogical concepts (like "harmonic rhythm" as a dedicated topic) don't have direct chapter equivalents
4. 🔗 All URLs should use format: `https://viva.pressbooks.pub/openmusictheory/chapter/[chapter-name]/`
