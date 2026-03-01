# Back Button Fix - Diagnostic Navigation

## Problem Identified ❌

When clicking the Back button from a diagnostic screen, the behavior was weird:
1. Click Back from diagnostic
2. Returns to intermediate diagnostic question (e.g., "Lacks clear direction")
3. Intermediate question immediately auto-advances back to diagnostic
4. **You're stuck in a loop** - can't go back further

**Root Cause:**
- Intermediate diagnostic questions (type: "diagnostic") were being added to `questionHistory`
- When going back, it would load these intermediate questions
- They would auto-advance immediately due to the `onCurrentQuestionChanged` watcher
- This created a navigation loop

---

## Solution Applied ✅

### Fix 1: Don't Add Diagnostic Questions to History
Modified `selectOption()` to skip adding diagnostic-type questions to history:

```javascript
if (questions[nextId].type !== "diagnostic") {
    questionHistory.push(nextId)
}
```

**Result:** Intermediate diagnostic questions are never in the history, so Back won't try to return to them.

### Fix 2: Skip Over Diagnostic Questions When Going Back
Modified `goBack()` to skip backwards over any diagnostic questions it encounters:

```javascript
while (questionHistory.length > 0) {
    var lastQuestionId = questionHistory[questionHistory.length - 1]
    if (questions[lastQuestionId] && questions[lastQuestionId].type === "diagnostic") {
        // Skip this intermediate diagnostic question
        questionHistory.pop()
        answerHistory.pop()
    } else {
        // Found a regular question, go back to it
        break
    }
}
```

**Result:** Double protection - even if a diagnostic question ended up in history, Back will skip over it.

---

## How Back Button Works Now

### Example Navigation Path:

1. **Start** → Select "Melody"
   - History: `["start", "melody_1"]`

2. **melody_1** → Select "Contour feels static"
   - History: `["start", "melody_1", "melody_contour"]`

3. **melody_contour** → Select "Lacks clear direction"
   - Loads `melody_contour_direction` (type: "diagnostic")
   - ❌ NOT added to history (skipped)
   - Auto-advances to diagnostic display
   - History: `["start", "melody_1", "melody_contour"]` (unchanged)

4. **Click Back** from diagnostic
   - Goes to last item in history: `"melody_contour"`
   - Shows question: "What about the contour specifically?"
   - ✅ Works correctly!

5. **Click Back** again
   - Goes to `"melody_1"`
   - Shows question: "What specifically about the melody feels problematic?"
   - ✅ Works correctly!

---

## Testing Paths

### Test 1: Basic Back from Diagnostic
1. Navigate: Start → Melody → Contour → Lacks clear direction
2. Click **Back**
3. Should show: "What about the contour specifically?" (the contour question)
4. ✅ No loop, no auto-advance

### Test 2: Multiple Backs
1. Navigate: Start → Melody → Contour → Lacks clear direction
2. Click **Back** (should go to contour question)
3. Click **Back** (should go to melody_1 question)
4. Click **Back** (should go to Start)
5. ✅ Each back goes one step further

### Test 3: Back Then Forward Again
1. Navigate to diagnostic
2. Click **Back** to contour question
3. Click different option (e.g., "Too much stepwise motion")
4. Should load new diagnostic
5. ✅ Forward navigation still works

---

## Technical Details

### questionHistory Behavior

**Before Fix:**
```
Start → melody_1 → melody_contour → melody_contour_direction
History: ["start", "melody_1", "melody_contour", "melody_contour_direction"]
                                                   ↑ auto-advances, causes loop
```

**After Fix:**
```
Start → melody_1 → melody_contour → [melody_contour_direction skipped] → diagnostic
History: ["start", "melody_1", "melody_contour"]
                                ↑ Back goes here (correct!)
```

### Protection Layers

1. **Prevention:** Don't add diagnostic questions to history in the first place
2. **Cleanup:** Skip over them if they somehow ended up in history
3. **Auto-advance:** Still automatically show diagnostic content

All three layers work together for smooth navigation.

---

## Impact

This fix affects:
- ✅ All melody diagnostics (15 endpoints)
- ✅ All harmony diagnostics (15 endpoints)
- ✅ Future branches (texture, rhythm, form, multiple)

Any diagnostic endpoint with an intermediate `type: "diagnostic"` question will now have correct Back button behavior.

---

## Status

**Bug:** ✅ FIXED
**Back button:** ✅ Works correctly from diagnostics
**Forward navigation:** ✅ Unchanged (still works)
**Auto-advance:** ✅ Still functions properly

The back button should now behave intuitively! 🎵
