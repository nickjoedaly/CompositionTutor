import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Muse.Ui 1.0
import Muse.UiComponents 1.0 as MU
import MuseScore 3.0

MuseScore {
    version: "1.0"
    title: "Composition Tutor"
    description: "Guided diagnostic tool for compositional problem-solving"
    categoryCode: "composing-arranging-tools"
    pluginType: "dialog"
    
    width: 1000
    height: 830
    
    // Make dialog resizable (both properties needed)
    property bool requiresResize: true
    
    // Native MuseScore theme is provided by ui.theme via Muse.Ui
    
    // State variables
    property var currentQuestion: null
    property var questionHistory: []
    property var answerHistory: []
    property string selectionInfo: ""
    property bool showingDiagnostic: false
    property var diagnosticData: null
    
    // Auto-advance diagnostic-type questions
    onCurrentQuestionChanged: {
        if (currentQuestion && currentQuestion.type === "diagnostic" && currentQuestion.next) {
            // Automatically trigger the diagnostic
            Qt.callLater(function() {
                if (currentQuestion.next.startsWith("diag_")) {
                    generateDiagnostic(currentQuestion.next)
                }
            })
        }
    }
    
    // Question tree structure
    property var questions: ({
        "start": {
            id: "start",
            text: "What feels off about this passage?",
            type: "choice",
            options: [
                { text: "Harmony", subtitle: "chord progression, voice leading", next: "harmony_1" },
                { text: "Melody", subtitle: "contour, direction, intervallic content", next: "melody_1" },
                { text: "Texture", subtitle: "density, register, spacing", next: "texture_1" },
                { text: "Rhythm", subtitle: "momentum, organization, pacing", next: "rhythm_1" },
                { text: "Form", subtitle: "proportion, placement, balance", next: "form_1" },
                { text: "Multiple / Unsure", subtitle: "", next: "multiple_1" }
            ]
        },
        
        "harmony_1": {
            id: "harmony_1",
            text: "What specifically about the harmony feels problematic?",
            type: "choice",
            options: [
                { text: "The progression feels aimless", subtitle: "no clear direction or goal", next: "harmony_aimless" },
                { text: "Voice leading is awkward", subtitle: "difficult to sing/play, or clunky motion", next: "harmony_voiceleading" },
                { text: "The arrival feels weak", subtitle: "destination chord doesn't land with weight", next: "harmony_arrival" },
                { text: "It's too predictable", subtitle: "clichéd or overly familiar", next: "harmony_predictable" },
                { text: "Harmonic rhythm feels off", subtitle: "chords change too fast/slow, or unevenly", next: "harmony_rhythm" },
                { text: "Something else I can't name yet", subtitle: "", next: "harmony_other" }
            ]
        },
        
        "harmony_aimless": {
            id: "harmony_aimless",
            text: "What kind of aimlessness?",
            type: "choice",
            options: [
                { text: "Circular", subtitle: "keeps returning to the same harmony, going nowhere", next: "diag_circular" },
                { text: "Meandering", subtitle: "wanders without establishing a trajectory", next: "diag_meandering" },
                { text: "Weak tonic", subtitle: "never settles on a clear home chord", next: "diag_weaktonic" },
                { text: "Missing pre-dominant", subtitle: "skips the approach to the goal", next: "diag_nopredominant" },
                { text: "I can describe it better in words", subtitle: "", next: "harmony_freeform" }
            ]
        },
        
        "harmony_voiceleading": {
            id: "harmony_voiceleading",
            text: "What type of voice leading issue?",
            type: "choice",
            options: [
                { text: "Large leaps", subtitle: "uncomfortable jumps in one or more voices", next: "diag_leaps" },
                { text: "Parallel motion problems", subtitle: "parallel 5ths, 8ves, or unisons", next: "diag_parallels" },
                { text: "Doubled leading tones or sevenths", subtitle: "problematic doublings", next: "diag_doublings" },
                { text: "Crossing voices", subtitle: "voices swap registers awkwardly", next: "diag_crossing" },
                { text: "Other voice leading issue", subtitle: "", next: "harmony_freeform" }
            ]
        },
        
        "harmony_arrival": {
            id: "harmony_arrival",
            text: "Why does the arrival feel weak?",
            type: "choice",
            options: [
                { text: "Weak predominant preparation", subtitle: "approach doesn't build expectation", next: "diag_weakpredominant" },
                { text: "Inverted or unstable goal chord", subtitle: "arrival chord isn't in root position", next: "diag_inversion" },
                { text: "Rhythmic placement undercuts it", subtitle: "lands on weak beat or wrong spot", next: "diag_rhythmplacement" },
                { text: "Textural thinning", subtitle: "arrival sounds empty or unsupported", next: "diag_texturalthin" },
                { text: "Other arrival issue", subtitle: "", next: "harmony_freeform" }
            ]
        },
        
        "harmony_predictable": {
            id: "harmony_predictable",
            text: "What makes it feel too predictable?",
            type: "choice",
            options: [
                { text: "Standard progressions", subtitle: "I-IV-V-I or similar clichés", next: "diag_cliche" },
                { text: "Lack of chromaticism", subtitle: "too diatonic, needs color", next: "diag_chromatic" },
                { text: "Harmonic rhythm too regular", subtitle: "metronomic chord changes", next: "diag_regularrhythm" },
                { text: "Other predictability issue", subtitle: "", next: "harmony_freeform" }
            ]
        },
        
        "harmony_rhythm": {
            id: "harmony_rhythm",
            text: "What's wrong with the harmonic rhythm?",
            type: "choice",
            options: [
                { text: "Too fast", subtitle: "chords change too frequently", next: "diag_toofast" },
                { text: "Too slow", subtitle: "chords last too long, feels static", next: "diag_tooslow" },
                { text: "Uneven or awkward", subtitle: "changes at wrong moments", next: "diag_uneven" },
                { text: "Other rhythm issue", subtitle: "", next: "harmony_freeform" }
            ]
        },
        
        "harmony_other": {
            id: "harmony_other",
            text: "Can you describe what feels wrong?",
            type: "text_input",
            next: "diag_generic_harmony"
        },
        
        "harmony_freeform": {
            id: "harmony_freeform",
            text: "Please describe the issue in your own words:",
            type: "text_input",
            next: "diag_generic_harmony"
        },
        
        // ========================================
        // MELODY BRANCH
        // ========================================
        
        "melody_1": {
            id: "melody_1",
            text: "What specifically about the melody feels problematic?",
            type: "choice",
            options: [
                { text: "The contour feels static or aimless", subtitle: "lacks shape, direction, or interest", next: "melody_contour" },
                { text: "Melodic leaps feel awkward", subtitle: "difficult to sing, or disconnected", next: "melody_leaps" },
                { text: "The range is problematic", subtitle: "too narrow, too wide, or poorly placed", next: "melody_range" },
                { text: "The melody lacks rhythmic interest", subtitle: "too predictable or monotonous", next: "melody_rhythm" },
                { text: "It doesn't fit the harmony well", subtitle: "clashes, or feels disconnected", next: "melody_harmony_fit" }
            ]
        },
        
        "melody_contour": {
            id: "melody_contour",
            text: "What about the contour specifically?",
            type: "choice",
            options: [
                { text: "Lacks clear direction", subtitle: "no peaks, goals, or trajectory", next: "melody_contour_direction" },
                { text: "Too much stepwise motion", subtitle: "scalic and tedious", next: "melody_contour_stepwise" },
                { text: "Too angular or jagged", subtitle: "excessive leaps without recovery", next: "melody_contour_angular" },
                { text: "Predictable patterns", subtitle: "mechanical repetition", next: "melody_contour_predictable" }
            ]
        },
        
        "melody_leaps": {
            id: "melody_leaps",
            text: "What makes the leaps feel awkward?",
            type: "choice",
            options: [
                { text: "Large leaps are difficult", subtitle: "intervals larger than 5th", next: "melody_leaps_large" },
                { text: "Awkward tritones or augmented intervals", subtitle: "unresolved tendency tones", next: "melody_leaps_tritone" },
                { text: "Consecutive leaps in same direction", subtitle: "compound motion without anchor", next: "melody_leaps_consecutive" }
            ]
        },
        
        "melody_range": {
            id: "melody_range",
            text: "What's problematic about the range?",
            type: "choice",
            options: [
                { text: "Too narrow/boring", subtitle: "insufficient registral space", next: "melody_range_narrow" },
                { text: "Too wide/unsingable", subtitle: "exceeds practical limits", next: "melody_range_wide" },
                { text: "Poorly placed in register", subtitle: "tessitura mismatch", next: "melody_range_placement" }
            ]
        },
        
        "melody_rhythm": {
            id: "melody_rhythm",
            text: "What about the melodic rhythm?",
            type: "choice",
            options: [
                { text: "Too much rhythmic repetition", subtitle: "mechanical pulse", next: "melody_rhythm_repetition" },
                { text: "No clear rhythmic motives", subtitle: "lacks identity", next: "melody_rhythm_motives" },
                { text: "Rhythm doesn't support phrasing", subtitle: "durational disconnect", next: "melody_rhythm_phrasing" }
            ]
        },
        
        "melody_harmony_fit": {
            id: "melody_harmony_fit",
            text: "How does the melody clash with harmony?",
            type: "choice",
            options: [
                { text: "Melody avoids chord tones", subtitle: "non-harmonic emphasis", next: "melody_harmony_avoids" },
                { text: "Too many non-chord tones", subtitle: "harmonic obscurity", next: "melody_harmony_too_many_nct" }
            ]
        },
        
        "melody_contour_direction": {
            id: "melody_contour_direction",
            text: "Lacks clear direction",
            type: "diagnostic",
            next: "diag_melody_contour_direction"
        },
        
        "melody_contour_stepwise": {
            id: "melody_contour_stepwise",
            text: "Too much stepwise motion",
            type: "diagnostic",
            next: "diag_melody_contour_stepwise"
        },
        
        "melody_contour_angular": {
            id: "melody_contour_angular",
            text: "Too angular or jagged",
            type: "diagnostic",
            next: "diag_melody_contour_angular"
        },
        
        "melody_contour_predictable": {
            id: "melody_contour_predictable",
            text: "Predictable patterns",
            type: "diagnostic",
            next: "diag_melody_contour_predictable"
        },
        
        "melody_leaps_large": {
            id: "melody_leaps_large",
            text: "Large leaps are difficult",
            type: "diagnostic",
            next: "diag_melody_leaps_large"
        },
        
        "melody_leaps_tritone": {
            id: "melody_leaps_tritone",
            text: "Awkward tritones or augmented intervals",
            type: "diagnostic",
            next: "diag_melody_leaps_tritone"
        },
        
        "melody_leaps_consecutive": {
            id: "melody_leaps_consecutive",
            text: "Consecutive leaps in same direction",
            type: "diagnostic",
            next: "diag_melody_leaps_consecutive"
        },
        
        "melody_range_narrow": {
            id: "melody_range_narrow",
            text: "Too narrow/boring",
            type: "diagnostic",
            next: "diag_melody_range_narrow"
        },
        
        "melody_range_wide": {
            id: "melody_range_wide",
            text: "Too wide/unsingable",
            type: "diagnostic",
            next: "diag_melody_range_wide"
        },
        
        "melody_range_placement": {
            id: "melody_range_placement",
            text: "Poorly placed in register",
            type: "diagnostic",
            next: "diag_melody_range_placement"
        },
        
        "melody_rhythm_repetition": {
            id: "melody_rhythm_repetition",
            text: "Too much rhythmic repetition",
            type: "diagnostic",
            next: "diag_melody_rhythm_repetition"
        },
        
        "melody_rhythm_motives": {
            id: "melody_rhythm_motives",
            text: "No clear rhythmic motives",
            type: "diagnostic",
            next: "diag_melody_rhythm_motives"
        },
        
        "melody_rhythm_phrasing": {
            id: "melody_rhythm_phrasing",
            text: "Rhythm doesn't support phrasing",
            type: "diagnostic",
            next: "diag_melody_rhythm_phrasing"
        },
        
        "melody_harmony_avoids": {
            id: "melody_harmony_avoids",
            text: "Melody avoids chord tones",
            type: "diagnostic",
            next: "diag_melody_harmony_avoids"
        },
        
        "melody_harmony_too_many_nct": {
            id: "melody_harmony_too_many_nct",
            text: "Too many non-chord tones",
            type: "diagnostic",
            next: "diag_melody_harmony_too_many_nct"
        },
        
        // ========================================
        // TEXTURE BRANCH
        // ========================================
        
        "texture_1": {
            id: "texture_1",
            text: "What specifically about the texture feels problematic?",
            type: "choice",
            options: [
                { text: "Too dense or thick", subtitle: "muddy, crowded, or hard to hear", next: "texture_density_thick" },
                { text: "Too sparse or thin", subtitle: "empty, weak, or lacking body", next: "texture_density_thin" },
                { text: "Voices overlap or clash", subtitle: "registral conflicts or poor spacing", next: "texture_spacing" },
                { text: "Rhythmic density is unbalanced", subtitle: "too much or too little activity", next: "texture_rhythm" },
                { text: "The texture doesn't change", subtitle: "monotonous, no variety", next: "texture_static" }
            ]
        },
        
        "texture_density_thick": {
            id: "texture_density_thick",
            text: "What makes it feel too thick?",
            type: "choice",
            options: [
                { text: "Too many simultaneous voices", subtitle: "voice saturation", next: "texture_thick_voices" },
                { text: "Narrow spacing creates muddiness", subtitle: "registral crowding", next: "texture_thick_spacing" },
                { text: "No registral hierarchy", subtitle: "foreground/background collapse", next: "texture_thick_hierarchy" }
            ]
        },
        
        "texture_density_thin": {
            id: "texture_density_thin",
            text: "What makes it feel too thin?",
            type: "choice",
            options: [
                { text: "Not enough voices for fullness", subtitle: "voice insufficiency", next: "texture_thin_voices" },
                { text: "Too much registral gap", subtitle: "empty middle register", next: "texture_thin_gap" },
                { text: "Weak bass foundation", subtitle: "bass inactivity", next: "texture_thin_bass" }
            ]
        },
        
        "texture_spacing": {
            id: "texture_spacing",
            text: "What about the spacing?",
            type: "choice",
            options: [
                { text: "Voices too close together", subtitle: "registral compression", next: "texture_spacing_close" },
                { text: "Voices cross frequently", subtitle: "voice independence loss", next: "texture_spacing_crossing" },
                { text: "Unbalanced register distribution", subtitle: "registral weighting", next: "texture_spacing_unbalanced" }
            ]
        },
        
        "texture_rhythm": {
            id: "texture_rhythm",
            text: "What about the rhythmic density?",
            type: "choice",
            options: [
                { text: "All voices move at once", subtitle: "homorhythmic rigidity", next: "texture_rhythm_homorhythm" },
                { text: "Too much activity everywhere", subtitle: "rhythmic saturation", next: "texture_rhythm_saturation" }
            ]
        },
        
        "texture_static": {
            id: "texture_static",
            text: "What doesn't change enough?",
            type: "choice",
            options: [
                { text: "Same number of voices throughout", subtitle: "textural monotony", next: "texture_static_voices" },
                { text: "No change in density or spacing", subtitle: "static architecture", next: "texture_static_architecture" }
            ]
        },
        
        "texture_thick_voices": {
            id: "texture_thick_voices",
            text: "Too many simultaneous voices",
            type: "diagnostic",
            next: "diag_texture_thick_voices"
        },
        
        "texture_thick_spacing": {
            id: "texture_thick_spacing",
            text: "Narrow spacing creates muddiness",
            type: "diagnostic",
            next: "diag_texture_thick_spacing"
        },
        
        "texture_thick_hierarchy": {
            id: "texture_thick_hierarchy",
            text: "No registral hierarchy",
            type: "diagnostic",
            next: "diag_texture_thick_hierarchy"
        },
        
        "texture_thin_voices": {
            id: "texture_thin_voices",
            text: "Not enough voices for fullness",
            type: "diagnostic",
            next: "diag_texture_thin_voices"
        },
        
        "texture_thin_gap": {
            id: "texture_thin_gap",
            text: "Too much registral gap",
            type: "diagnostic",
            next: "diag_texture_thin_gap"
        },
        
        "texture_thin_bass": {
            id: "texture_thin_bass",
            text: "Weak bass foundation",
            type: "diagnostic",
            next: "diag_texture_thin_bass"
        },
        
        "texture_spacing_close": {
            id: "texture_spacing_close",
            text: "Voices too close together",
            type: "diagnostic",
            next: "diag_texture_spacing_close"
        },
        
        "texture_spacing_crossing": {
            id: "texture_spacing_crossing",
            text: "Voices cross frequently",
            type: "diagnostic",
            next: "diag_texture_spacing_crossing"
        },
        
        "texture_spacing_unbalanced": {
            id: "texture_spacing_unbalanced",
            text: "Unbalanced register distribution",
            type: "diagnostic",
            next: "diag_texture_spacing_unbalanced"
        },
        
        "texture_rhythm_homorhythm": {
            id: "texture_rhythm_homorhythm",
            text: "All voices move at once",
            type: "diagnostic",
            next: "diag_texture_rhythm_homorhythm"
        },
        
        "texture_rhythm_saturation": {
            id: "texture_rhythm_saturation",
            text: "Too much activity everywhere",
            type: "diagnostic",
            next: "diag_texture_rhythm_saturation"
        },
        
        "texture_static_voices": {
            id: "texture_static_voices",
            text: "Same number of voices throughout",
            type: "diagnostic",
            next: "diag_texture_static_voices"
        },
        
        "texture_static_architecture": {
            id: "texture_static_architecture",
            text: "No change in density or spacing",
            type: "diagnostic",
            next: "diag_texture_static_architecture"
        },
        
        // ========================================
        // RHYTHM BRANCH
        // ========================================
        
        "rhythm_1": {
            id: "rhythm_1",
            text: "What specifically about the rhythm feels problematic?",
            type: "choice",
            options: [
                { text: "No sense of forward motion", subtitle: "static, stagnant, or lacking drive", next: "rhythm_momentum" },
                { text: "The pacing feels wrong", subtitle: "too rushed or too slow", next: "rhythm_pacing" },
                { text: "Rhythmic patterns are predictable", subtitle: "mechanical or monotonous", next: "rhythm_predictable" },
                { text: "Meter feels unclear or wrong", subtitle: "downbeats obscured, or metric conflict", next: "rhythm_meter" },
                { text: "Rhythm doesn't support phrasing", subtitle: "durational disconnect from structure", next: "rhythm_phrasing" }
            ]
        },
        
        "rhythm_momentum": {
            id: "rhythm_momentum",
            text: "What creates the lack of momentum?",
            type: "choice",
            options: [
                { text: "Too many long notes", subtitle: "durational stagnation", next: "rhythm_momentum_long" },
                { text: "No rhythmic acceleration toward goals", subtitle: "flat trajectory", next: "rhythm_momentum_acceleration" },
                { text: "Equal durations create monotony", subtitle: "rhythmic homogeneity", next: "rhythm_momentum_equal" }
            ]
        },
        
        "rhythm_pacing": {
            id: "rhythm_pacing",
            text: "What feels wrong about the pacing?",
            type: "choice",
            options: [
                { text: "Too much activity", subtitle: "rhythmic saturation", next: "rhythm_pacing_busy" },
                { text: "Changes happen too quickly", subtitle: "temporal compression", next: "rhythm_pacing_fast" },
                { text: "Changes happen too slowly", subtitle: "temporal dilation", next: "rhythm_pacing_slow" }
            ]
        },
        
        "rhythm_predictable": {
            id: "rhythm_predictable",
            text: "What makes the rhythm predictable?",
            type: "choice",
            options: [
                { text: "Mechanical, unchanging patterns", subtitle: "rhythmic automation", next: "rhythm_predictable_mechanical" },
                { text: "Overly regular phrase rhythm", subtitle: "square periodicity", next: "rhythm_predictable_regular" },
                { text: "No syncopation or rhythmic surprise", subtitle: "metric complacency", next: "rhythm_predictable_syncopation" }
            ]
        },
        
        "rhythm_meter": {
            id: "rhythm_meter",
            text: "What's problematic about the meter?",
            type: "choice",
            options: [
                { text: "Downbeats aren't clear", subtitle: "metric ambiguity", next: "rhythm_meter_downbeats" },
                { text: "Wrong time signature", subtitle: "notational mismatch", next: "rhythm_meter_signature" },
                { text: "Competing metric layers", subtitle: "metric dissonance", next: "rhythm_meter_competing" }
            ]
        },
        
        "rhythm_phrasing": {
            id: "rhythm_phrasing",
            text: "How does rhythm obscure phrasing?",
            type: "choice",
            options: [
                { text: "Durations obscure phrase boundaries", subtitle: "syntactic blurring", next: "rhythm_phrasing_boundaries" },
                { text: "No agogic accent", subtitle: "flat durational contour", next: "rhythm_phrasing_agogic" }
            ]
        },
        
        "rhythm_momentum_long": {
            id: "rhythm_momentum_long",
            text: "Too many long notes",
            type: "diagnostic",
            next: "diag_rhythm_momentum_long"
        },
        
        "rhythm_momentum_acceleration": {
            id: "rhythm_momentum_acceleration",
            text: "No rhythmic acceleration toward goals",
            type: "diagnostic",
            next: "diag_rhythm_momentum_acceleration"
        },
        
        "rhythm_momentum_equal": {
            id: "rhythm_momentum_equal",
            text: "Equal durations create monotony",
            type: "diagnostic",
            next: "diag_rhythm_momentum_equal"
        },
        
        "rhythm_pacing_busy": {
            id: "rhythm_pacing_busy",
            text: "Too much activity",
            type: "diagnostic",
            next: "diag_rhythm_pacing_busy"
        },
        
        "rhythm_pacing_fast": {
            id: "rhythm_pacing_fast",
            text: "Changes happen too quickly",
            type: "diagnostic",
            next: "diag_rhythm_pacing_fast"
        },
        
        "rhythm_pacing_slow": {
            id: "rhythm_pacing_slow",
            text: "Changes happen too slowly",
            type: "diagnostic",
            next: "diag_rhythm_pacing_slow"
        },
        
        "rhythm_predictable_mechanical": {
            id: "rhythm_predictable_mechanical",
            text: "Mechanical, unchanging patterns",
            type: "diagnostic",
            next: "diag_rhythm_predictable_mechanical"
        },
        
        "rhythm_predictable_regular": {
            id: "rhythm_predictable_regular",
            text: "Overly regular phrase rhythm",
            type: "diagnostic",
            next: "diag_rhythm_predictable_regular"
        },
        
        "rhythm_predictable_syncopation": {
            id: "rhythm_predictable_syncopation",
            text: "No syncopation or rhythmic surprise",
            type: "diagnostic",
            next: "diag_rhythm_predictable_syncopation"
        },
        
        "rhythm_meter_downbeats": {
            id: "rhythm_meter_downbeats",
            text: "Downbeats aren't clear",
            type: "diagnostic",
            next: "diag_rhythm_meter_downbeats"
        },
        
        "rhythm_meter_signature": {
            id: "rhythm_meter_signature",
            text: "Wrong time signature",
            type: "diagnostic",
            next: "diag_rhythm_meter_signature"
        },
        
        "rhythm_meter_competing": {
            id: "rhythm_meter_competing",
            text: "Competing metric layers",
            type: "diagnostic",
            next: "diag_rhythm_meter_competing"
        },
        
        "rhythm_phrasing_boundaries": {
            id: "rhythm_phrasing_boundaries",
            text: "Durations obscure phrase boundaries",
            type: "diagnostic",
            next: "diag_rhythm_phrasing_boundaries"
        },
        
        "rhythm_phrasing_agogic": {
            id: "rhythm_phrasing_agogic",
            text: "No agogic accent",
            type: "diagnostic",
            next: "diag_rhythm_phrasing_agogic"
        },
        
        // ========================================
        // FORM BRANCH
        // ========================================
        
        "form_1": {
            id: "form_1",
            text: "What specifically about the form or structure feels problematic?",
            type: "choice",
            options: [
                { text: "Sections feel unbalanced", subtitle: "one part too long or too short", next: "form_proportion" },
                { text: "Transitions are awkward", subtitle: "sections don't connect smoothly", next: "form_transitions" },
                { text: "No clear formal boundaries", subtitle: "sections blur together", next: "form_boundaries" },
                { text: "The form feels predictable", subtitle: "too conventional or obvious", next: "form_predictable" },
                { text: "Return or recapitulation is weak", subtitle: "doesn't feel like arrival", next: "form_return" }
            ]
        },
        
        "form_proportion": {
            id: "form_proportion",
            text: "Which section feels out of proportion?",
            type: "choice",
            options: [
                { text: "Opening section too long", subtitle: "expositional excess", next: "form_proportion_opening" },
                { text: "Development too short", subtitle: "insufficient contrast", next: "form_proportion_development" },
                { text: "Ending feels rushed", subtitle: "truncated resolution", next: "form_proportion_ending" }
            ]
        },
        
        "form_transitions": {
            id: "form_transitions",
            text: "What makes the transitions awkward?",
            type: "choice",
            options: [
                { text: "Abrupt section changes", subtitle: "formal disjunction", next: "form_transitions_abrupt" },
                { text: "Too much overlap/elision", subtitle: "boundary collapse", next: "form_transitions_overlap" },
                { text: "Key change feels unmotivated", subtitle: "modulatory disjunction", next: "form_transitions_key" }
            ]
        },
        
        "form_boundaries": {
            id: "form_boundaries",
            text: "Why are boundaries unclear?",
            type: "choice",
            options: [
                { text: "Cadences are weak or absent", subtitle: "syntactic ambiguity", next: "form_boundaries_cadences" },
                { text: "Phrase lengths obscure structure", subtitle: "proportional ambiguity", next: "form_boundaries_phrases" },
                { text: "No textural or thematic boundary markers", subtitle: "continuous texture", next: "form_boundaries_markers" }
            ]
        },
        
        "form_predictable": {
            id: "form_predictable",
            text: "What makes the form predictable?",
            type: "choice",
            options: [
                { text: "Too conventional", subtitle: "generic form template", next: "form_predictable_conventional" },
                { text: "No surprises or deviations", subtitle: "formal automation", next: "form_predictable_surprises" }
            ]
        },
        
        "form_return": {
            id: "form_return",
            text: "What's weak about the return?",
            type: "choice",
            options: [
                { text: "Recapitulation too literal", subtitle: "mechanical return", next: "form_return_literal" },
                { text: "Return doesn't feel like resolution", subtitle: "weak formal arrival", next: "form_return_resolution" },
                { text: "No sense of completion", subtitle: "inconclusive ending", next: "form_return_completion" }
            ]
        },
        
        "form_proportion_opening": {
            id: "form_proportion_opening",
            text: "Opening section too long",
            type: "diagnostic",
            next: "diag_form_proportion_opening"
        },
        
        "form_proportion_development": {
            id: "form_proportion_development",
            text: "Development too short",
            type: "diagnostic",
            next: "diag_form_proportion_development"
        },
        
        "form_proportion_ending": {
            id: "form_proportion_ending",
            text: "Ending feels rushed",
            type: "diagnostic",
            next: "diag_form_proportion_ending"
        },
        
        "form_transitions_abrupt": {
            id: "form_transitions_abrupt",
            text: "Abrupt section changes",
            type: "diagnostic",
            next: "diag_form_transitions_abrupt"
        },
        
        "form_transitions_overlap": {
            id: "form_transitions_overlap",
            text: "Too much overlap/elision",
            type: "diagnostic",
            next: "diag_form_transitions_overlap"
        },
        
        "form_transitions_key": {
            id: "form_transitions_key",
            text: "Key change feels unmotivated",
            type: "diagnostic",
            next: "diag_form_transitions_key"
        },
        
        "form_boundaries_cadences": {
            id: "form_boundaries_cadences",
            text: "Cadences are weak or absent",
            type: "diagnostic",
            next: "diag_form_boundaries_cadences"
        },
        
        "form_boundaries_phrases": {
            id: "form_boundaries_phrases",
            text: "Phrase lengths obscure structure",
            type: "diagnostic",
            next: "diag_form_boundaries_phrases"
        },
        
        "form_boundaries_markers": {
            id: "form_boundaries_markers",
            text: "No textural or thematic boundary markers",
            type: "diagnostic",
            next: "diag_form_boundaries_markers"
        },
        
        "form_predictable_conventional": {
            id: "form_predictable_conventional",
            text: "Too conventional",
            type: "diagnostic",
            next: "diag_form_predictable_conventional"
        },
        
        "form_predictable_surprises": {
            id: "form_predictable_surprises",
            text: "No surprises or deviations",
            type: "diagnostic",
            next: "diag_form_predictable_surprises"
        },
        
        "form_return_literal": {
            id: "form_return_literal",
            text: "Recapitulation too literal",
            type: "diagnostic",
            next: "diag_form_return_literal"
        },
        
        "form_return_resolution": {
            id: "form_return_resolution",
            text: "Return doesn't feel like resolution",
            type: "diagnostic",
            next: "diag_form_return_resolution"
        },
        
        "form_return_completion": {
            id: "form_return_completion",
            text: "No sense of completion",
            type: "diagnostic",
            next: "diag_form_return_completion"
        },
        
        // ========================================
        // MULTIPLE/UNSURE BRANCH
        // ========================================
        
        "multiple_1": {
            id: "multiple_1",
            text: "What's making it difficult to identify the issue?",
            type: "choice",
            options: [
                { text: "Multiple problems at once", subtitle: "several things feel wrong", next: "multiple_interconnected" },
                { text: "It's more of a general feeling", subtitle: "can't pinpoint specifics", next: "multiple_intuitive" },
                { text: "The issue is about overall effect", subtitle: "mood, character, or expression", next: "multiple_holistic" },
                { text: "I can describe it better in words", subtitle: "use AI chat for discussion", next: "multiple_describe" }
            ]
        },
        
        "multiple_interconnected": {
            id: "multiple_interconnected",
            text: "Multiple problems at once",
            type: "diagnostic",
            next: "diag_multiple_interconnected"
        },
        
        "multiple_intuitive": {
            id: "multiple_intuitive",
            text: "It's more of a general feeling",
            type: "diagnostic",
            next: "diag_multiple_intuitive"
        },
        
        "multiple_holistic": {
            id: "multiple_holistic",
            text: "The issue is about overall effect",
            type: "diagnostic",
            next: "diag_multiple_holistic"
        },
        
        "multiple_describe": {
            id: "multiple_describe",
            text: "I can describe it better in words",
            type: "diagnostic",
            next: "diag_multiple_describe"
        },
        
        "placeholder": {
            id: "placeholder",
            text: "This diagnostic branch is under development. For now, you can discuss this with Claude AI.",
            type: "placeholder",
            next: "diag_placeholder"
        }
    })
    
    // Diagnostic content database
    property var diagnostics: ({
        "diag_meandering": {
            reframing: "If your goal is to create clearer harmonic direction, the issue may be that the progression lacks a functional framework. Meandering progressions often result from treating each chord as locally satisfying without considering the phrase-level trajectory.",
            solutions: [
                "Establish a functional skeleton — Identify tonic, pre-dominant, and dominant zones, then embed your current chords within them",
                "Create bass-line direction — Design a strong bass trajectory (scale, arpeggiation) and build chords above it",
                "Compress to essentials — Remove harmonies that don't contribute to forward motion, even if they sound good in isolation"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/intro-to-harmony/",
            omtTitle: "Introduction to Harmony",
            readings: [
                "Kostka & Payne, Tonal Harmony (Ch. 5: Principles of Voice Leading)",
                "Caplin, Classical Form (Ch. 4: Phrase Structure)"
            ]
        },
        
        "diag_circular": {
            reframing: "If your goal is to break out of harmonic circularity, consider that returning repeatedly to the same chord can create stasis rather than stability. The difference lies in whether the returns mark progress toward a goal or simply delay arrival.",
            solutions: [
                "Directional bass motion — Use stepwise or goal-oriented bass movement instead of returning to the same bass note",
                "Expand the harmonic palette — Introduce secondary dominants or chromatic chords to create tension that resolves elsewhere",
                "Asymmetric phrase structure — Vary the length of time spent on each harmony to create forward propulsion"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/intro-to-harmony/",
            omtTitle: "Introduction to Harmony",
            readings: [
                "Schenker, Free Composition (on prolongation vs. repetition)",
                "Aldwell & Schachter, Harmony and Voice Leading (Ch. 8: Prolongation)"
            ]
        },
        
        "diag_weaktonic": {
            reframing: "If your goal is to establish a clear tonic, the issue may be insufficient emphasis through repetition, metric placement, or harmonic approach. A weak tonic often results from treating it as just another chord rather than a gravitational center.",
            solutions: [
                "Strong cadences — Use authentic cadences (V-I or V7-I in root position) at structurally important moments",
                "Metric emphasis — Place tonic arrivals on strong beats or downbeats",
                "Durational weight — Let the tonic chord last longer than surrounding harmonies",
                "Bass emphasis — Ensure the tonic appears in the bass at key moments"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/strong-predominants/",
            omtTitle: "Strong Predominants",
            readings: [
                "Piston, Harmony (Ch. 2: Triads and Harmonic Functions)",
                "Rameau, Treatise on Harmony (on the fundamental bass)"
            ]
        },
        
        "diag_nopredominant": {
            reframing: "If your goal is to create a stronger sense of arrival, the missing link may be the predominant function. Moving directly from tonic to dominant can feel abrupt; the predominant zone creates expectation and momentum.",
            solutions: [
                "Add predominant harmony — Insert ii, IV, or ii6 before the dominant",
                "Expand predominant zone — Use multiple predominant chords (IV-ii6-V) for stronger approach",
                "Applied dominants to V — Use V/V to intensify the arrival at the dominant"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/tonicization/",
            omtTitle: "Tonicization",
            readings: [
                "Kostka & Payne, Tonal Harmony (Ch. 7: Harmonic Rhythm and Meter)",
                "Caplin, Classical Form (Ch. 2: Cadences)"
            ]
        },
        
        "diag_leaps": {
            reframing: "If your goal is smoother voice leading, large leaps often indicate that you're prioritizing vertical sonority over horizontal motion. Stepwise motion is generally more singable and creates stronger linear connections.",
            solutions: [
                "Contrary motion — When one voice leaps, move other voices in the opposite direction by step",
                "Voice exchange — Let voices trade notes rather than leaping to new material",
                "Reassign material — Move the leaping line to a different voice or instrument better suited to it",
                "Add passing tones — Fill in leaps with non-chord tones to create stepwise motion"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/chords-in-satb-style/",
            omtTitle: "Chords in SATB Style",
            readings: [
                "Fux, Gradus ad Parnassum (species counterpoint principles)",
                "Aldwell & Schachter, Harmony and Voice Leading (Ch. 3: The Melodic Line)"
            ]
        },
        
        "diag_parallels": {
            reframing: "If your goal is to avoid parallel perfect intervals, recognize that parallel fifths and octaves reduce polyphonic independence by making voices sound like a single line. This may or may not matter depending on your stylistic context.",
            solutions: [
                "Contrary or oblique motion — Move one voice stepwise in the opposite direction or keep it stationary",
                "Invert one chord — Change bass position to break the parallel motion pattern",
                "Redistribute voices — Assign the problematic notes to different instruments or registers",
                "Stylistic consideration — In some contexts (modal, minimalist, pop), parallels may be acceptable or even desirable"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/chords-in-satb-style/",
            omtTitle: "Chords in SATB Style",
            readings: [
                "Knud Jeppesen, Counterpoint (on independence of voices)",
                "Kostka & Payne, Tonal Harmony (Ch. 6: Root Position Part Writing)"
            ]
        },
        
        "diag_doublings": {
            reframing: "If your goal is better voicing, doubled leading tones or chord sevenths create problems because these tones have strong tendencies (leading tone up, seventh down). Doubling them forces one to resolve incorrectly or creates parallel octaves.",
            solutions: [
                "Double the root instead — Most stable option in most chords",
                "Omit the fifth — In seventh chords, you can often omit the fifth and triple the root",
                "Voice in three parts — Reduce to three voices temporarily to avoid the doubling",
                "Redistribute — Move the doubling to a different chord member"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/chords-in-satb-style/",
            omtTitle: "Chords in SATB Style",
            readings: [
                "Piston, Harmony (Ch. 4: The Dominant Seventh Chord)",
                "Aldwell & Schachter, Harmony and Voice Leading (Ch. 6: The Leading Tone)"
            ]
        },
        
        "diag_crossing": {
            reframing: "If your goal is clearer voice leading, voice crossing can create confusion about which line is which, especially for listeners. However, brief crossing for specific effect can be effective.",
            solutions: [
                "Maintain registral ordering — Keep soprano above alto, alto above tenor, etc.",
                "Inversion substitution — Use a different chord inversion to avoid the crossing",
                "Spacing adjustment — Redistribute the chord to maintain separation",
                "Strategic crossing — If crossing serves a specific expressive purpose, ensure it's temporary and clearly audible"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/chords-in-satb-style/",
            omtTitle: "Chords in SATB Style",
            readings: [
                "Aldwell & Schachter, Harmony and Voice Leading (Ch. 4: Spacing and Registration)"
            ]
        },
        
        "diag_weakpredominant": {
            reframing: "If your goal is a stronger arrival, the predominant harmony may not be creating sufficient expectation. Weak predominants often result from poor voice leading approach, weak metric placement, or lack of durational emphasis.",
            solutions: [
                "Strengthen predominant choice — Use ii6/5 or IV with added 6th for more tension",
                "Expand predominant duration — Let the predominant last longer to build expectation",
                "Add predominant expansion — Use multiple predominant chords (I6/4-ii6-V) for extended approach",
                "Improve voice leading into V — Ensure smooth, directed motion into the dominant"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/strengthening-endings-with-v7/",
            omtTitle: "Strengthening Endings with V7",
            readings: [
                "Caplin, Classical Form (Ch. 2: Cadential Progressions)",
                "Kostka & Payne, Tonal Harmony (Ch. 9: Cadences)"
            ]
        },
        
        "diag_inversion": {
            reframing: "If your goal is a stronger arrival, inverted goal chords often sound provisional or transitional rather than conclusive. Root position provides maximum stability and finality.",
            solutions: [
                "Use root position — Place the tonic in the bass for the arrival",
                "Melodic adjustment — Rearrange upper voices to accommodate root position bass",
                "Structural rethinking — Consider whether this is truly meant to be a strong arrival or a half cadence",
                "If inversion is intentional — Ensure it serves a specific expressive purpose (e.g., continuity rather than closure)"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/strengthening-endings-with-v7/",
            omtTitle: "Strengthening Endings with V7",
            readings: [
                "Caplin, Classical Form (Ch. 2: Perfect Authentic Cadence)",
                "Piston, Harmony (Ch. 5: Inversions)"
            ]
        },
        
        "diag_rhythmplacement": {
            reframing: "If your goal is a stronger arrival, rhythmic placement matters enormously. Arrivals on weak beats or at unexpected metrical locations can sound like they're 'missing' the target.",
            solutions: [
                "Downbeat arrival — Place the goal chord on beat 1 of the measure",
                "Extend approach — Delay the arrival to land on the next strong beat",
                "Durational emphasis — Make the arrival chord longer than surrounding harmonies",
                "Textural reinforcement — Add rhythmic activity or doubling at the arrival point"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/performing-harmonic-analysis-using-the-phrase-model/",
            omtTitle: "Performing Harmonic Analysis",
            readings: [
                "Lerdahl & Jackendoff, A Generative Theory of Tonal Music (on metrical accent)",
                "Rothstein, Phrase Rhythm in Tonal Music (on hypermeter)"
            ]
        },
        
        "diag_texturalthin": {
            reframing: "If your goal is a more substantial arrival, textural thinning at the goal can undermine its importance. Major arrivals typically benefit from full texture, registral spread, and clear doublings.",
            solutions: [
                "Add voices — Increase the number of sounding parts at the arrival",
                "Register expansion — Spread the chord across a wider range",
                "Doubling at arrival — Double important tones (root, melody) for emphasis",
                "Dynamic reinforcement — Consider crescendo leading to the arrival"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/texture/",
            omtTitle: "Texture",
            readings: [
                "Schoenberg, Fundamentals of Musical Composition (on texture and emphasis)",
                "Rimsky-Korsakov, Principles of Orchestration (on doubling and weight)"
            ]
        },
        
        "diag_cliche": {
            reframing: "If your goal is to avoid predictable progressions, recognize that standard patterns (I-IV-V-I) are 'standard' because they work effectively. The issue may be lack of surface variety rather than the underlying harmonic logic.",
            solutions: [
                "Chromatic elaboration — Add secondary dominants, borrowed chords, or altered chords within the progression",
                "Inversion variety — Use different inversions to create more interesting bass motion",
                "Deceptive resolution — Interrupt expected progressions with substitutions (V-vi instead of V-I)",
                "Extended progressions — Insert additional harmonies between the standard functions"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/tonicization/",
            omtTitle: "Tonicization",
            readings: [
                "Piston, Harmony (Ch. 12: Secondary Dominants)",
                "Kostka & Payne, Tonal Harmony (Ch. 17: Applied Chords)"
            ]
        },
        
        "diag_chromatic": {
            reframing: "If your goal is more harmonic color, chromatic chords can add richness and surprise. However, chromaticism should serve the phrase direction, not distract from it.",
            solutions: [
                "Applied dominants — Tonicize scale degrees other than the tonic",
                "Modal mixture — Borrow chords from parallel minor/major",
                "Augmented sixth chords — Use for intensified predominant function",
                "Chromatic mediants — Move to chords a third away with altered quality (e.g., C major to Ab major)"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/tonicization/",
            omtTitle: "Tonicization",
            readings: [
                "Kostka & Payne, Tonal Harmony (Ch. 21: Modal Mixture)",
                "Piston, Harmony (Ch. 18: Chromatic Mediants)"
            ]
        },
        
        "diag_regularrhythm": {
            reframing: "If your goal is more varied harmonic rhythm, too-regular chord changes can sound mechanical. Harmonic rhythm should respond to melodic shape, phrase structure, and metric emphasis.",
            solutions: [
                "Vary chord duration — Let some harmonies last longer than others",
                "Align with phrase structure — Change harmonies less frequently at phrase beginnings, more at cadences",
                "Syncopation — Place chord changes off the beat occasionally",
                "Surface vs. structural rhythm — Maintain steady surface activity while underlying harmonies move more slowly"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/performing-harmonic-analysis-using-the-phrase-model/",
            omtTitle: "Performing Harmonic Analysis",
            readings: [
                "Kostka & Payne, Tonal Harmony (Ch. 7: Harmonic Rhythm)",
                "Rothstein, Phrase Rhythm in Tonal Music"
            ]
        },
        
        "diag_toofast": {
            reframing: "If your goal is clearer harmony, chord changes that are too rapid can prevent listeners from hearing each harmony clearly. Fast harmonic rhythm works best with simple melodic activity.",
            solutions: [
                "Reduce chord changes — Let harmonies last longer, especially at phrase beginnings",
                "Prolongation — Use passing chords or suspensions instead of full harmonic changes",
                "Pedal points — Hold one note (often bass) while upper harmonies change above it",
                "Simplify progression — Use fewer distinct harmonies in the phrase"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/performing-harmonic-analysis-using-the-phrase-model/",
            omtTitle: "Performing Harmonic Analysis",
            readings: [
                "Kostka & Payne, Tonal Harmony (Ch. 7: Harmonic Rhythm)"
            ]
        },
        
        "diag_tooslow": {
            reframing: "If your goal is more harmonic momentum, static harmonies can drain energy from the phrase. Slow harmonic rhythm works best when melodic activity or other parameters create forward motion.",
            solutions: [
                "Increase chord changes — Add harmonic motion, especially approaching cadences",
                "Melodic elaboration — If harmony must stay static, increase melodic activity and ornamentation",
                "Textural variation — Change texture or orchestration even if harmony stays the same",
                "Bass motion — Create motion in the bass even when upper harmony is static"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/performing-harmonic-analysis-using-the-phrase-model/",
            omtTitle: "Performing Harmonic Analysis",
            readings: [
                "Kostka & Payne, Tonal Harmony (Ch. 7: Harmonic Rhythm)"
            ]
        },
        
        "diag_uneven": {
            reframing: "If your goal is more balanced harmonic rhythm, awkward or uneven chord changes often result from not aligning harmonic motion with metric emphasis and phrase structure.",
            solutions: [
                "Align with meter — Change harmonies on strong beats when possible",
                "Match phrase structure — Speed up harmonic rhythm approaching cadences, slow down at beginnings",
                "Consistent patterns — If establishing a pattern of chord changes, maintain it or vary it deliberately",
                "Grouping logic — Ensure chord durations create clear rhythmic groupings"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/performing-harmonic-analysis-using-the-phrase-model/",
            omtTitle: "Performing Harmonic Analysis",
            readings: [
                "Rothstein, Phrase Rhythm in Tonal Music",
                "Lerdahl & Jackendoff, A Generative Theory of Tonal Music"
            ]
        },
        
        "diag_generic_harmony": {
            reframing: "Based on your description, the issue may involve multiple interacting factors. Harmonic problems often have several possible causes and solutions.",
            solutions: [
                "Analyze the bass line — Does it have clear direction and shape?",
                "Check voice leading — Are all voices moving smoothly and independently?",
                "Examine harmonic function — Does each chord serve a clear tonic, predominant, or dominant role?",
                "Consider harmonic rhythm — Are chord changes aligned with metric and phrase structure?",
                "Evaluate the cadence — Does the phrase end with a clear goal?"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/intro-to-harmony/",
            omtTitle: "Introduction to Harmony",
            readings: [
                "Kostka & Payne, Tonal Harmony (comprehensive approach)",
                "Piston, Harmony (comprehensive approach)"
            ]
        },
        
        
        // ========================================
        // MELODY DIAGNOSTICS
        // ========================================
        
        "diag_melody_contour_direction": {
            reframing: "If your goal is to create a stronger sense of melodic direction, the issue may be that the contour lacks clear registral goals or trajectory. Melodies without directional shape can feel wandering or purposeless.",
            solutions: [
                "Establish an apex — Place the melodic high point strategically (often 2/3 through the phrase) to create registral destination",
                "Use wedge or arch shapes — Design the contour to expand outward from center, or rise to a peak and descend",
                "Create compensatory motion — After ascending, descend proportionally; after leaps, move by step",
                "Goal-directed motion — Aim melodic gestures toward specific structural pitches (cadential tones, chord members)"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/melody-and-phrasing/",
            omtTitle: "Melody and Phrasing",
            readings: [
                "Rothstein, Phrase Rhythm in Tonal Music",
                "Schoenberg, Fundamentals of Musical Composition (Ch. 3)",
                "Salzer & Schachter, Counterpoint in Composition"
            ]
        },
        
        "diag_melody_contour_stepwise": {
            reframing: "If your goal is to add melodic interest, the issue may be that excessive stepwise motion creates a scalic, predictable quality. While conjunct motion is singable, too much can feel mechanical.",
            solutions: [
                "Intervallic variety — Introduce leaps (3rds, 4ths, 5ths) to break up scalar passages",
                "Arpeggiation — Outline chords rather than scales to create harmonic clarity",
                "Neighbor embellishment — Use neighbor tones to create local variety within scalar motion",
                "Sequential patterns — Transform scalar material through transposition or rhythmic variation"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/embellishing-tones/",
            omtTitle: "Embellishing Tones",
            readings: [
                "Schenker, Free Composition (on prolongation)",
                "Fux, Gradus ad Parnassum (melodic principles)",
                "Salzer, Structural Hearing"
            ]
        },
        
        "diag_melody_contour_angular": {
            reframing: "If your goal is to create a more singable or balanced melody, the issue may be that excessive leaps without stepwise recovery create a jagged, disconnected contour. Disjunct motion needs compensation.",
            solutions: [
                "Stepwise compensation — After a leap, move by step in the opposite direction to recover",
                "Conjunct filling — Connect disjunct pitches with passing tones over time",
                "Registral balance — Balance upward leaps with descending motion (and vice versa)",
                "Limit consecutive leaps — Avoid compound leaps (multiple leaps in same direction) without stepwise anchoring"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/first-species-counterpoint/",
            omtTitle: "First Species Counterpoint",
            readings: [
                "Jeppesen, Counterpoint (melodic writing principles)",
                "Fux, Gradus ad Parnassum",
                "Rothstein, Phrase Rhythm in Tonal Music"
            ]
        },
        
        "diag_melody_contour_predictable": {
            reframing: "If your goal is to reduce melodic predictability, the issue may be mechanical repetition without development. Patterns need variation to maintain interest.",
            solutions: [
                "Varied repetition — Change register, rhythm, or ornamentation on subsequent iterations",
                "Rhythmic displacement — Shift pattern entries relative to the beat or measure",
                "Registral transposition — Repeat patterns in different octaves or registers",
                "Fragmentation or expansion — Develop patterns by shortening or extending their material"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/melody-and-phrasing/",
            omtTitle: "Melody and Phrasing",
            readings: [
                "Schoenberg, Fundamentals of Musical Composition (developing variation)",
                "Caplin, Classical Form (sentence structure)",
                "Ratz, Einführung in die musikalische Formenlehre"
            ]
        },
        
        "diag_melody_leaps_large": {
            reframing: "If your goal is to make large leaps more singable, the issue may be that intervals larger than a fifth lack preparation or resolution. Large leaps need contextual support.",
            solutions: [
                "Stepwise approach or departure — Lead into or away from large leaps with conjunct motion",
                "Arpeggiate harmony — Large leaps work better when outlining underlying chord structures",
                "Registral goals — Use large leaps to reach important structural pitches (apex, cadence points)",
                "Limit consecutive large leaps — Follow one large leap with stepwise recovery before another"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/first-species-counterpoint/",
            omtTitle: "First Species Counterpoint",
            readings: [
                "Fux, Gradus ad Parnassum",
                "Jeppesen, Counterpoint",
                "Schenker, Free Composition"
            ]
        },
        
        "diag_melody_leaps_tritone": {
            reframing: "If your goal is to resolve awkward tritones or augmented intervals, the issue may be unresolved tendency tones or lack of harmonic context. These intervals need voice-leading justification.",
            solutions: [
                "Voice leading resolution — Resolve tendency tones (leading tone up, seventh down) by step",
                "Harmonic context — Ensure tritones appear in clear dominant or diminished chord contexts",
                "Chromatic passing — Approach or leave augmented intervals with chromatic motion",
                "Melodic chromatic lines — Use augmented intervals within coherent chromatic voice leading"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/intervals/",
            omtTitle: "Intervals",
            readings: [
                "Aldwell & Schachter, Harmony and Voice Leading (Ch. 10)",
                "Piston, Harmony (dissonance treatment)",
                "Forte, Tonal Harmony in Concept and Practice"
            ]
        },
        
        "diag_melody_leaps_consecutive": {
            reframing: "If your goal is to address consecutive leaps in the same direction, the issue may be compound motion without registral anchoring. Multiple leaps create disconnection.",
            solutions: [
                "Registral return — After consecutive leaps, return toward the starting register",
                "Change direction — After one leap, move in the opposite direction",
                "Stepwise recovery — Insert conjunct motion between or after leaps",
                "Limit to arpeggiation — Consecutive leaps work best when outlining a single chord"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/first-species-counterpoint/",
            omtTitle: "First Species Counterpoint",
            readings: [
                "Fux, Gradus ad Parnassum",
                "Jeppesen, Counterpoint",
                "Salzer & Schachter, Counterpoint in Composition"
            ]
        },
        
        "diag_melody_range_narrow": {
            reframing: "If your goal is to expand melodic interest, the issue may be insufficient registral space. Narrow ranges can feel confined or monotonous.",
            solutions: [
                "Expand gradually — Widen the range over the course of the phrase or piece",
                "Use registral climax — Place the highest or lowest note at structurally important moments",
                "Create arch trajectory — Design phrases that expand to a peak and contract",
                "Balance high and low — Explore both upper and lower boundaries of the intended range"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/melody-and-phrasing/",
            omtTitle: "Melody and Phrasing",
            readings: [
                "Rothstein, Phrase Rhythm in Tonal Music",
                "Schoenberg, Fundamentals of Musical Composition",
                "Berry, Structural Functions in Music"
            ]
        },
        
        "diag_melody_range_wide": {
            reframing: "If your goal is to make the melody more singable or practical, the issue may be that the range exceeds performable limits. Wide ranges can be unidiomatic.",
            solutions: [
                "Octave redistribution — Move extreme pitches into a more comfortable register",
                "Register consolidation — Reduce the overall span by bringing outliers toward the center",
                "Tessitura planning — Consider the comfortable middle range for the intended voice/instrument",
                "Voice redistribution — Move some melodic material to other voices or parts"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/16th-century-contrapuntal-style/",
            omtTitle: "16th-Century Contrapuntal Style",
            readings: [
                "Aldwell & Schachter, Harmony and Voice Leading (ranges)",
                "Kostka & Payne, Tonal Harmony (vocal ranges)",
                "Adler, The Study of Orchestration"
            ]
        },
        
        "diag_melody_range_placement": {
            reframing: "If your goal is to improve registral placement, the issue may be tessitura mismatch—the melody sits in an uncomfortable or ineffective range for its intended voice or instrument.",
            solutions: [
                "Transpose — Move the entire melody to a more appropriate register",
                "Redistribute voices — Assign melodic material to different voices with suitable ranges",
                "Consider instrumental limitations — Check idiomatic ranges for the intended medium",
                "Balance with accompaniment — Ensure melody sits above or below other voices as needed"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/chords-in-satb-style/",
            omtTitle: "Chords in SATB Style",
            readings: [
                "Adler, The Study of Orchestration",
                "Piston, Orchestration",
                "Rimsky-Korsakov, Principles of Orchestration"
            ]
        },
        
        "diag_melody_rhythm_repetition": {
            reframing: "If your goal is to add rhythmic variety, the issue may be that excessive rhythmic repetition creates a mechanical pulse. Rhythmic sameness reduces melodic interest.",
            solutions: [
                "Varied note values — Mix shorter and longer durations within phrases",
                "Syncopation — Place melodic accents off the beat for rhythmic surprise",
                "Durational variety — Avoid repeating the same rhythmic pattern too frequently",
                "Rhythmic development — Transform rhythmic motives through augmentation, diminution, or displacement"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/melody-and-phrasing/",
            omtTitle: "Melody and Phrasing",
            readings: [
                "Cooper & Meyer, The Rhythmic Structure of Music",
                "Lerdahl & Jackendoff, A Generative Theory of Tonal Music",
                "Rothstein, Phrase Rhythm in Tonal Music"
            ]
        },
        
        "diag_melody_rhythm_motives": {
            reframing: "If your goal is to establish melodic identity, the issue may be lack of clear rhythmic motives. Melodies need rhythmic characterization to be memorable.",
            solutions: [
                "Establish a motif — Create a distinctive rhythmic pattern at the opening",
                "Develop rhythmically — Repeat and transform the rhythmic motif throughout",
                "Create rhythmic sequence — Maintain rhythmic pattern while varying pitches",
                "Rhythmic anchoring — Use consistent rhythmic cells to unify disparate melodic material"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/melody-and-phrasing/",
            omtTitle: "Melody and Phrasing",
            readings: [
                "Schoenberg, Fundamentals of Musical Composition",
                "Ratz, Einführung in die musikalische Formenlehre",
                "Caplin, Classical Form"
            ]
        },
        
        "diag_melody_rhythm_phrasing": {
            reframing: "If your goal is to align rhythm with phrasing, the issue may be durational disconnect—the rhythmic surface doesn't articulate phrase boundaries or structural moments.",
            solutions: [
                "Align durations with syntax — Place longer notes at phrase boundaries and cadences",
                "Use agogic accent — Emphasize important pitches through duration rather than dynamics",
                "Rhythmic elision — Use overlapping durations to create phrase connections",
                "Cadential lengthening — Extend final notes to mark phrase endings clearly"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/melody-and-phrasing/",
            omtTitle: "Melody and Phrasing",
            readings: [
                "Rothstein, Phrase Rhythm in Tonal Music",
                "Lerdahl & Jackendoff, A Generative Theory of Tonal Music",
                "Cooper & Meyer, The Rhythmic Structure of Music"
            ]
        },
        
        "diag_melody_harmony_avoids": {
            reframing: "If your goal is to strengthen the connection between melody and harmony, the issue may be that non-harmonic tones are metrically emphasized while chord tones are weak. Harmonic clarity comes from emphasizing chord members.",
            solutions: [
                "Emphasize chord tones metrically — Place chord members on downbeats and strong beats",
                "Approach by step — Lead into chord tones with passing or neighbor motion",
                "Chord tone arrival — Design melodic gestures to land on chord members at structurally important moments",
                "Consonant framework — Ensure the rhythmic skeleton of the melody outlines the harmony"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/embellishing-tones/",
            omtTitle: "Embellishing Tones",
            readings: [
                "Schenker, Free Composition",
                "Salzer, Structural Hearing",
                "Aldwell & Schachter, Harmony and Voice Leading (Ch. 4-5)"
            ]
        },
        
        "diag_melody_harmony_too_many_nct": {
            reframing: "If your goal is to clarify harmonic function, the issue may be that excessive non-chord tones obscure the underlying harmony. Too much dissonance can blur harmonic identity.",
            solutions: [
                "Strengthen downbeats — Place chord tones on metrically strong positions",
                "Consonant emphasis — Give chord tones longer durations than passing/neighbor tones",
                "Clarify function — Ensure that functional moments (predominant, dominant, tonic) are consonantly clear",
                "Reduce embellishment density — Use fewer non-chord tones or place them on weaker beats"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/embellishing-tones/",
            omtTitle: "Embellishing Tones",
            readings: [
                "Aldwell & Schachter, Harmony and Voice Leading (Ch. 6-7)",
                "Kostka & Payne, Tonal Harmony (embellishment)",
                "Schenker, Free Composition"
            ]
        },
        
        // ========================================
        // TEXTURE DIAGNOSTICS
        // ========================================
        
        "diag_texture_thick_voices": {
            reframing: "If your goal is to reduce textural density, the issue may be voice saturation—too many simultaneous parts competing for attention. Density is about perception, not just part count.",
            solutions: [
                "Selective reduction — Remove voices strategically, keeping those essential to harmony and line",
                "Voice pairing — Combine similar voices into unison or octaves rather than independent lines",
                "Staggered entrances — Have voices enter and exit at different times rather than all sounding together",
                "Textural relief — Create passages with fewer voices to provide contrast and breathing space"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/texture/",
            omtTitle: "Texture",
            readings: [
                "Piston, Orchestration (textural balance)",
                "Adler, The Study of Orchestration (Ch. 18: Scoring)",
                "Berry, Structural Functions in Music (textural rhythm)"
            ]
        },
        
        "diag_texture_thick_spacing": {
            reframing: "If your goal is to clarify the texture, the issue may be registral crowding—voices packed too closely together create muddiness, especially in lower registers. Spacing affects blend and clarity.",
            solutions: [
                "Open position — Space voices with wider intervals, especially below middle C",
                "Register separation — Move voices into distinct registral zones with space between",
                "Octave doublings — Instead of adding new pitches, double existing ones at the octave",
                "Bass clarity — Ensure at least an octave between bass and next voice in low register"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/chords-in-satb-style/",
            omtTitle: "Chords in SATB Style",
            readings: [
                "Rimsky-Korsakov, Principles of Orchestration",
                "Piston, Harmony (voicing principles)",
                "Kennan, The Technique of Orchestration"
            ]
        },
        
        "diag_texture_thick_hierarchy": {
            reframing: "If your goal is to establish foreground/background relationships, the issue may be lack of registral hierarchy—all voices have equal prominence, creating an undifferentiated sonic mass. Texture needs stratification.",
            solutions: [
                "Dynamic levels — Assign different dynamic layers to create foreground, middleground, background",
                "Orchestration — Use timbre to distinguish melodic from accompanimental material",
                "Registral stratification — Place primary material in prominent register, support in others",
                "Articulation contrast — Use different articulations (legato vs. staccato) to separate layers"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/texture/",
            omtTitle: "Texture",
            readings: [
                "Berry, Structural Functions in Music",
                "Schenker, Free Composition (layers)",
                "Cone, Musical Form and Musical Performance"
            ]
        },
        
        "diag_texture_thin_voices": {
            reframing: "If your goal is to create fuller texture, the issue may be voice insufficiency—not enough parts to fill the sonic space. Fullness depends on register coverage and harmonic completeness.",
            solutions: [
                "Add voices — Introduce additional parts to fill harmonic gaps",
                "Octave doublings — Double existing lines at the octave for weight without adding pitches",
                "Wider spacing — Spread voices across more registers to cover more sonic space",
                "Pedal points — Add sustained bass or inner pedals for harmonic foundation"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/texture/",
            omtTitle: "Texture",
            readings: [
                "Piston, Orchestration",
                "Rimsky-Korsakov, Principles of Orchestration",
                "Adler, The Study of Orchestration"
            ]
        },
        
        "diag_texture_thin_gap": {
            reframing: "If your goal is to fill registral gaps, the issue may be empty middle register—upper and lower voices present, but nothing connecting them. This creates a hollow quality.",
            solutions: [
                "Close position — Move voices closer together to eliminate registral holes",
                "Inner voice filling — Add or activate inner voices in the empty register",
                "Register consolidation — Bring outer voices toward the center to reduce span",
                "Pedal or drone — Add sustained middle-register pedal to fill the gap"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/chords-in-satb-style/",
            omtTitle: "Chords in SATB Style",
            readings: [
                "Piston, Harmony (spacing principles)",
                "Kostka & Payne, Tonal Harmony (voicing)",
                "Rimsky-Korsakov, Principles of Orchestration"
            ]
        },
        
        "diag_texture_thin_bass": {
            reframing: "If your goal is to strengthen the foundation, the issue may be bass inactivity—the lowest voice lacks motion or weight, creating instability. Bass motion drives harmonic rhythm and grounding.",
            solutions: [
                "Bass motion — Add more frequent bass changes, arpeggiation, or passing motion",
                "Arpeggiation — Have the bass outline chord changes rather than sustaining",
                "Octave reinforcement — Double the bass at the octave below for added weight",
                "Rhythmic activation — Give the bass more rhythmic variety and momentum"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/chords-in-satb-style/",
            omtTitle: "Chords in SATB Style",
            readings: [
                "Schenker, Free Composition (bass motion)",
                "Rameau, Treatise on Harmony (fundamental bass)",
                "Piston, Harmony (bass position)"
            ]
        },
        
        "diag_texture_spacing_close": {
            reframing: "If your goal is to improve clarity, the issue may be registral compression—voices clustered too tightly make it difficult to hear individual lines. Spacing affects voice independence.",
            solutions: [
                "Open position — Spread voices with wider intervals between adjacent parts",
                "Register separation — Place voices in distinct registral zones",
                "Selective voicing — Use only essential voices, spaced widely",
                "Octave displacement — Move some voices up or down an octave to create space"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/chords-in-satb-style/",
            omtTitle: "Chords in SATB Style",
            readings: [
                "Rimsky-Korsakov, Principles of Orchestration",
                "Piston, Harmony (spacing rules)",
                "Kennan, The Technique of Orchestration"
            ]
        },
        
        "diag_texture_spacing_crossing": {
            reframing: "If your goal is to maintain voice independence, the issue may be frequent voice crossing—when voices switch registral positions, it obscures identity and creates confusion. Crossing should be purposeful.",
            solutions: [
                "Maintain registral hierarchy — Keep voices in consistent registral order (S-A-T-B)",
                "Voice identity — Ensure each voice has clear registral territory",
                "Avoid crossing — Redesign voice leading to eliminate unnecessary crossings",
                "When crossing is needed — Make it brief and clear, then restore normal order"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/chords-in-satb-style/",
            omtTitle: "Chords in SATB Style",
            readings: [
                "Jeppesen, Counterpoint (voice independence)",
                "Fux, Gradus ad Parnassum",
                "Piston, Harmony (voice crossing)"
            ]
        },
        
        "diag_texture_spacing_unbalanced": {
            reframing: "If your goal is to balance the texture, the issue may be registral weighting—disproportionate distribution of voices creates imbalance. Some registers are crowded while others are empty.",
            solutions: [
                "Balanced spacing — Distribute voices proportionally across the registral space",
                "Proportional distribution — More voices in middle register, fewer at extremes",
                "Register awareness — Consider the natural weight of different registers",
                "Adjust doubling — Move doublings to underrepresented registers"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/chords-in-satb-style/",
            omtTitle: "Chords in SATB Style",
            readings: [
                "Rimsky-Korsakov, Principles of Orchestration",
                "Piston, Orchestration (balance)",
                "Adler, The Study of Orchestration"
            ]
        },
        
        "diag_texture_rhythm_homorhythm": {
            reframing: "If your goal is to create rhythmic variety, the issue may be homorhythmic rigidity—all voices moving in identical rhythm creates a monolithic texture. Rhythmic independence adds life.",
            solutions: [
                "Stagger rhythms — Give different voices different rhythmic patterns",
                "Voice independence — Allow some voices to sustain while others move",
                "Rhythmic offset — Delay some voices by a beat or fraction",
                "Syncopation — Place some voices on weak beats while others articulate strong beats"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/texture/",
            omtTitle: "Texture",
            readings: [
                "Jeppesen, Counterpoint (rhythmic independence)",
                "Fux, Gradus ad Parnassum (species principles)",
                "Rothstein, Phrase Rhythm in Tonal Music"
            ]
        },
        
        "diag_texture_rhythm_saturation": {
            reframing: "If your goal is to reduce busyness, the issue may be rhythmic saturation—constant activity in all voices creates fatigue and obscures important motion. Texture needs breathing space.",
            solutions: [
                "Selective rest — Have some voices rest while others remain active",
                "Voice reduction — Remove less essential voices during busy passages",
                "Rhythmic contrast — Alternate between active and sustained textures",
                "Breathing space — Create moments of textural stillness or simplicity"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/texture/",
            omtTitle: "Texture",
            readings: [
                "Berry, Structural Functions in Music",
                "Cone, Musical Form and Musical Performance",
                "Meyer, Explaining Music"
            ]
        },
        
        "diag_texture_static_voices": {
            reframing: "If your goal is to add textural variety, the issue may be textural monotony—maintaining the same number of voices throughout creates sameness. Textural change provides formal articulation.",
            solutions: [
                "Voice addition/subtraction — Gradually add or remove voices over time",
                "Textural variation — Alternate between full and reduced textures",
                "Buildup/reduction — Create dramatic trajectories through voice accumulation or loss",
                "Sectional contrast — Use different voice counts for different formal sections"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/texture/",
            omtTitle: "Texture",
            readings: [
                "Berry, Structural Functions in Music (textural rhythm)",
                "Cone, Musical Form and Musical Performance",
                "Caplin, Classical Form (textural types)"
            ]
        },
        
        "diag_texture_static_architecture": {
            reframing: "If your goal is to create textural development, the issue may be static architecture—unchanging density and spacing throughout. Textural trajectory provides shape and forward motion.",
            solutions: [
                "Textural contrast — Vary between thick and thin, high and low",
                "Register shifts — Move the textural center of gravity over time",
                "Dynamic shaping — Use crescendo/diminuendo with textural change",
                "Articulation variety — Vary between legato, staccato, marcato across sections"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/texture/",
            omtTitle: "Texture",
            readings: [
                "Berry, Structural Functions in Music",
                "Meyer, Explaining Music (textural change)",
                "Cone, Musical Form and Musical Performance"
            ]
        },
        
        // ========================================
        // RHYTHM DIAGNOSTICS
        // ========================================
        
        "diag_rhythm_momentum_long": {
            reframing: "If your goal is to create forward motion, the issue may be durational stagnation—too many sustained notes reduce rhythmic energy. Motion comes from change and activity.",
            solutions: [
                "Subdivide durations — Break longer notes into shorter articulated values",
                "Add rhythmic activity — Introduce moving voices or figuration during sustained tones",
                "Rhythmic acceleration — Gradually shorten note values as phrases progress",
                "Surface rhythm — Create faster-moving ornamental or accompanimental layers"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/notating-rhythm/",
            omtTitle: "Notating Rhythm",
            readings: [
                "Cooper & Meyer, The Rhythmic Structure of Music",
                "Lerdahl & Jackendoff, A Generative Theory of Tonal Music",
                "Rothstein, Phrase Rhythm in Tonal Music"
            ]
        },
        
        "diag_rhythm_momentum_acceleration": {
            reframing: "If your goal is to create goal-directed motion, the issue may be flat rhythmic trajectory—the pace doesn't intensify toward structural arrivals. Acceleration creates expectation and satisfaction.",
            solutions: [
                "Increase activity — Use progressively shorter note values approaching cadences",
                "Faster harmonic rhythm — Change chords more frequently as phrases progress",
                "Syncopation buildup — Introduce or intensify syncopation before arrivals",
                "Metric compression — Use hemiola or other metric shifts to create urgency"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/melody-and-phrasing/",
            omtTitle: "Melody and Phrasing",
            readings: [
                "Rothstein, Phrase Rhythm in Tonal Music",
                "Lerdahl & Jackendoff, A Generative Theory of Tonal Music",
                "Cooper & Meyer, The Rhythmic Structure of Music"
            ]
        },
        
        "diag_rhythm_momentum_equal": {
            reframing: "If your goal is to add rhythmic variety, the issue may be rhythmic homogeneity—uniform durations create predictability and reduce interest. Variety comes from contrast.",
            solutions: [
                "Varied durations — Mix quarter notes, eighths, sixteenths, dotted rhythms",
                "Dotted rhythms — Use dotted figures for energy and character",
                "Triplet contrast — Introduce triplets against duple divisions",
                "Durational hierarchy — Establish patterns of long-short relationships"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/notating-rhythm/",
            omtTitle: "Notating Rhythm",
            readings: [
                "Cooper & Meyer, The Rhythmic Structure of Music",
                "Berry, Structural Functions in Music",
                "Schoenberg, Fundamentals of Musical Composition"
            ]
        },
        
        "diag_rhythm_pacing_busy": {
            reframing: "If your goal is to reduce busyness, the issue may be rhythmic saturation—constant activity creates fatigue without allowing events to register. Rest and space enhance perception.",
            solutions: [
                "Longer durations — Use half notes, whole notes to create breathing space",
                "Strategic rests — Insert rests to punctuate and create space",
                "Textural reduction — Simplify accompanying voices during busy melody",
                "Rhythmic contrast — Alternate active passages with calmer sections"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/notating-rhythm/",
            omtTitle: "Notating Rhythm",
            readings: [
                "Berry, Structural Functions in Music",
                "Cone, Musical Form and Musical Performance",
                "Meyer, Explaining Music"
            ]
        },
        
        "diag_rhythm_pacing_fast": {
            reframing: "If your goal is to allow events to settle, the issue may be temporal compression—changes happen too rapidly for perception to process. Pacing needs proportion to scale.",
            solutions: [
                "Extend durations — Lengthen individual events to allow absorption",
                "Slower harmonic rhythm — Let chords sustain longer before changing",
                "Reduce event density — Eliminate some changes to allow others to breathe",
                "Textural simplification — Use fewer simultaneous events during transitions"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/performing-harmonic-analysis-using-the-phrase-model/",
            omtTitle: "Performing Harmonic Analysis",
            readings: [
                "Rothstein, Phrase Rhythm in Tonal Music",
                "Berry, Structural Functions in Music",
                "Meyer, Explaining Music"
            ]
        },
        
        "diag_rhythm_pacing_slow": {
            reframing: "If your goal is to increase energy, the issue may be temporal dilation—events unfold too slowly, creating stagnation. Forward motion requires appropriate pacing.",
            solutions: [
                "Increase activity — Use shorter note values and more frequent events",
                "Faster harmonic rhythm — Change chords more frequently",
                "Compress events — Reduce durations between structural moments",
                "Surface activity — Add faster-moving figuration or ornamentation"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/performing-harmonic-analysis-using-the-phrase-model/",
            omtTitle: "Performing Harmonic Analysis",
            readings: [
                "Rothstein, Phrase Rhythm in Tonal Music",
                "Cooper & Meyer, The Rhythmic Structure of Music",
                "Lerdahl & Jackendoff, A Generative Theory of Tonal Music"
            ]
        },
        
        "diag_rhythm_predictable_mechanical": {
            reframing: "If your goal is to reduce rhythmic predictability, the issue may be rhythmic automation—unchanging patterns create mechanical quality. Variation maintains interest.",
            solutions: [
                "Varied repetition — Alter rhythmic patterns on subsequent iterations",
                "Rhythmic displacement — Shift pattern entries relative to the beat",
                "Pattern breaking — Interrupt regular patterns with contrasting material",
                "Developmental variation — Transform patterns through augmentation, diminution, fragmentation"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/melody-and-phrasing/",
            omtTitle: "Melody and Phrasing",
            readings: [
                "Schoenberg, Fundamentals of Musical Composition",
                "Rothstein, Phrase Rhythm in Tonal Music",
                "Ratz, Einführung in die musikalische Formenlehre"
            ]
        },
        
        "diag_rhythm_predictable_regular": {
            reframing: "If your goal is to add phrase-level variety, the issue may be square periodicity—overly regular phrase lengths (always 4 or 8 bars) create predictability. Asymmetry adds interest.",
            solutions: [
                "Phrase extension — Add extra measures to expected phrase lengths",
                "Phrase elision — Overlap phrase endings with beginnings",
                "Irregular lengths — Use 3-, 5-, 6-, 7-bar phrases",
                "Asymmetry — Combine phrases of different lengths (4+6, 3+5, etc.)"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/phrase-archetypes-unique-forms/",
            omtTitle: "Phrase Archetypes",
            readings: [
                "Rothstein, Phrase Rhythm in Tonal Music",
                "Caplin, Classical Form",
                "Schoenberg, Fundamentals of Musical Composition"
            ]
        },
        
        "diag_rhythm_predictable_syncopation": {
            reframing: "If your goal is to add rhythmic surprise, the issue may be metric complacency—all accents fall predictably on downbeats. Syncopation creates energy and interest.",
            solutions: [
                "Syncopation — Place accents on weak beats or off the beat",
                "Off-beat emphasis — Accent the 'and' of beats rather than beat itself",
                "Metric displacement — Shift melodic material by an eighth or quarter note",
                "Hemiola — Create 3-against-2 or 2-against-3 metric patterns"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/metrical-dissonance/",
            omtTitle: "Metrical Dissonance",
            readings: [
                "Lerdahl & Jackendoff, A Generative Theory of Tonal Music",
                "Krebs, Fantasy Pieces (metric dissonance)",
                "Rothstein, Phrase Rhythm in Tonal Music"
            ]
        },
        
        "diag_rhythm_meter_downbeats": {
            reframing: "If your goal is to clarify meter, the issue may be metric ambiguity—downbeats aren't sufficiently marked, making the pulse unclear. Meter needs articulation.",
            solutions: [
                "Emphasize downbeats — Place important harmonic changes, melodic peaks, or bass motion on beat 1",
                "Harmonic arrivals — Align cadences and chord changes with metric accents",
                "Durational accent — Use longer notes on downbeats to create agogic emphasis",
                "Bass motion — Ensure bass moves on strong beats to reinforce meter"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/simple-meter-and-time-signatures/",
            omtTitle: "Simple Meter and Time Signatures",
            readings: [
                "Lerdahl & Jackendoff, A Generative Theory of Tonal Music",
                "Cooper & Meyer, The Rhythmic Structure of Music",
                "Berry, Structural Functions in Music"
            ]
        },
        
        "diag_rhythm_meter_signature": {
            reframing: "If your goal is notational clarity, the issue may be notational mismatch—the written meter doesn't reflect the perceived grouping. Notation should aid, not obscure, perception.",
            solutions: [
                "Re-barring — Change bar lines to align with perceived downbeats",
                "Change time signature — Switch to a meter that matches the rhythmic grouping",
                "Compound vs. simple — Consider whether 6/8 vs. 3/4 better represents the feel",
                "Mixed meter — Use changing meters if groupings vary throughout"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/simple-meter-and-time-signatures/",
            omtTitle: "Simple Meter and Time Signatures",
            readings: [
                "Lerdahl & Jackendoff, A Generative Theory of Tonal Music",
                "Rothstein, Phrase Rhythm in Tonal Music",
                "Krebs, Fantasy Pieces"
            ]
        },
        
        "diag_rhythm_meter_competing": {
            reframing: "If your goal is to manage metric complexity, the issue may be metric dissonance—competing metric layers create ambiguity or conflict. This can be expressive if controlled, problematic if unintentional.",
            solutions: [
                "Clarify intention — Decide if metric conflict is desired or accidental",
                "Hemiola control — Use 3-against-2 patterns deliberately and resolve them",
                "Polymeter management — If using different meters simultaneously, balance their relative strength",
                "Resolution — Bring competing layers into alignment at structural moments"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/metrical-dissonance/",
            omtTitle: "Metrical Dissonance",
            readings: [
                "Krebs, Fantasy Pieces: Metrical Dissonance in the Music of Robert Schumann",
                "Lerdahl & Jackendoff, A Generative Theory of Tonal Music",
                "Cohn, Complex Hemiolas"
            ]
        },
        
        "diag_rhythm_phrasing_boundaries": {
            reframing: "If your goal is to clarify phrase structure, the issue may be syntactic blurring—durations obscure where phrases begin and end. Rhythm should articulate form.",
            solutions: [
                "Cadential lengthening — Extend final notes of phrases to mark endings",
                "Clear arrivals — Use longer durations at phrase boundaries",
                "Durational punctuation — Follow phrase endings with rests or long notes",
                "Anacrusis clarity — Use pickup notes to mark phrase beginnings clearly"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/melody-and-phrasing/",
            omtTitle: "Melody and Phrasing",
            readings: [
                "Rothstein, Phrase Rhythm in Tonal Music",
                "Caplin, Classical Form",
                "Lerdahl & Jackendoff, A Generative Theory of Tonal Music"
            ]
        },
        
        "diag_rhythm_phrasing_agogic": {
            reframing: "If your goal is to emphasize important notes, the issue may be flat durational contour—all notes have similar lengths, creating no hierarchical emphasis. Duration creates weight.",
            solutions: [
                "Lengthen important notes — Give structurally significant pitches longer durations",
                "Durational stress — Use duration rather than dynamics for emphasis",
                "Agogic emphasis — Place longer notes on melodic peaks, cadence tones, or chord changes",
                "Durational variety — Create hierarchy through long-short relationships"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/melody-and-phrasing/",
            omtTitle: "Melody and Phrasing",
            readings: [
                "Rothstein, Phrase Rhythm in Tonal Music",
                "Berry, Structural Functions in Music",
                "Cooper & Meyer, The Rhythmic Structure of Music"
            ]
        },
        
        // ========================================
        // FORM DIAGNOSTICS
        // ========================================
        
        "diag_form_proportion_opening": {
            reframing: "If your goal is to balance formal proportions, the issue may be expositional excess—the opening section is too long relative to what follows. Proportion affects perception of structure.",
            solutions: [
                "Compression — Reduce repetition, combine ideas, eliminate transitional material",
                "Delay development — Move contrasting or developmental material earlier",
                "Front-load material — Present main ideas more efficiently at the outset",
                "Strategic cuts — Remove measures that don't advance the exposition"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/formal-sections-in-general/",
            omtTitle: "Formal Sections in General",
            readings: [
                "Caplin, Classical Form (expositional function)",
                "Hepokoski & Darcy, Elements of Sonata Theory",
                "Rosen, Sonata Forms"
            ]
        },
        
        "diag_form_proportion_development": {
            reframing: "If your goal is to create sufficient contrast, the issue may be insufficient developmental space—the middle section is too brief to explore possibilities. Development needs time.",
            solutions: [
                "Extend contrast section — Add more measures for exploration and departure",
                "Fragmentation — Break themes into smaller units for development",
                "Modulation — Visit additional keys to expand tonal trajectory",
                "Sequential treatment — Use sequences to extend developmental passages"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/sonata-form/",
            omtTitle: "Sonata Form",
            readings: [
                "Caplin, Classical Form (developmental function)",
                "Hepokoski & Darcy, Elements of Sonata Theory",
                "Rosen, Sonata Forms"
            ]
        },
        
        "diag_form_proportion_ending": {
            reframing: "If your goal is to provide satisfying closure, the issue may be truncated resolution—the ending is too brief to satisfy the expectations created. Endings need weight.",
            solutions: [
                "Extend cadential space — Add measures after the final cadence for settling",
                "Coda addition — Create a concluding section that reinforces closure",
                "Plagal extension — Add plagal motion (IV-I) after authentic cadence",
                "Tonic prolongation — Sustain or elaborate the final tonic harmony"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/formal-sections-in-general/",
            omtTitle: "Formal Sections in General",
            readings: [
                "Caplin, Classical Form (closing sections)",
                "Hepokoski & Darcy, Elements of Sonata Theory",
                "Agawu, Playing with Signs"
            ]
        },
        
        "diag_form_transitions_abrupt": {
            reframing: "If your goal is to create smooth connections, the issue may be formal disjunction—sections change without preparation or linkage. Transitions bridge formal gaps.",
            solutions: [
                "Transitional passage — Insert connecting material between sections",
                "Preparation — Foreshadow the new section through harmony, texture, or rhythm",
                "Retransition — Create a passage that leads back to the return",
                "Elision with preparation — Overlap sections but prepare the new material"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/formal-sections-in-general/",
            omtTitle: "Formal Sections in General",
            readings: [
                "Caplin, Classical Form (transitions)",
                "Hepokoski & Darcy, Elements of Sonata Theory",
                "Rosen, Sonata Forms"
            ]
        },
        
        "diag_form_transitions_overlap": {
            reframing: "If your goal is to clarify boundaries, the issue may be boundary collapse—excessive elision blurs where one section ends and another begins. Some articulation is needed.",
            solutions: [
                "Clear cadence — Provide definitive cadential closure before the next section",
                "Breathing space — Insert brief silence or textural pause between sections",
                "Articulation — Use fermata, caesura, or rest to mark the boundary",
                "Reduce overlap — Separate the ending of one section from the beginning of the next"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/harmonic-elision/",
            omtTitle: "Harmonic Elision",
            readings: [
                "Caplin, Classical Form (phrase overlaps)",
                "Rothstein, Phrase Rhythm in Tonal Music",
                "Schmalfeldt, In the Process of Becoming"
            ]
        },
        
        "diag_form_transitions_key": {
            reframing: "If your goal is to make modulations convincing, the issue may be modulatory disjunction—key changes feel arbitrary or unprepared. Modulation needs motivic or harmonic logic.",
            solutions: [
                "Pivot preparation — Use common chords or tones to bridge keys",
                "Sequential transition — Use sequences to move gradually through key areas",
                "Chromatic voice leading — Connect keys through stepwise chromatic motion",
                "Enharmonic reinterpretation — Use enharmonic pivots for distant modulations"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/extended-tonicization-and-modulation-to-closely-related-keys/",
            omtTitle: "Extended Tonicization and Modulation",
            readings: [
                "Schoenberg, Structural Functions of Harmony (modulation)",
                "Aldwell & Schachter, Harmony and Voice Leading (Ch. 27-29)",
                "Piston, Harmony (modulation techniques)"
            ]
        },
        
        "diag_form_boundaries_cadences": {
            reframing: "If your goal is to clarify formal divisions, the issue may be syntactic ambiguity—weak or absent cadences fail to mark section endings. Cadences are primary boundary markers.",
            solutions: [
                "PAC strengthening — Ensure perfect authentic cadences at section boundaries",
                "Dominant preparation — Build V or V7 before cadential arrivals",
                "Cadential weight — Give cadences metrical, durational, and textural emphasis",
                "Avoid deceptive cadences — At boundaries, use conclusive rather than evaded cadences"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/strengthening-endings-with-v7/",
            omtTitle: "Strengthening Endings with V7",
            readings: [
                "Caplin, Classical Form (cadential articulation)",
                "Rothstein, Phrase Rhythm in Tonal Music",
                "Schmalfeldt, In the Process of Becoming"
            ]
        },
        
        "diag_form_boundaries_phrases": {
            reframing: "If your goal is to clarify structure through phrase organization, the issue may be proportional ambiguity—irregular or obscured phrase lengths make formal boundaries unclear. Regularity aids perception.",
            solutions: [
                "Regular phrase lengths — Use consistent 4- or 8-bar units at boundaries",
                "Clear antecedent-consequent — Establish balanced phrase pairs",
                "Metric clarity — Align phrases with metric strong points",
                "Hypermeter — Establish clear larger-scale metric structure"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/phrase-archetypes-unique-forms/",
            omtTitle: "Phrase Archetypes",
            readings: [
                "Rothstein, Phrase Rhythm in Tonal Music",
                "Caplin, Classical Form",
                "Lerdahl & Jackendoff, A Generative Theory of Tonal Music"
            ]
        },
        
        "diag_form_boundaries_markers": {
            reframing: "If your goal is to mark formal divisions, the issue may be continuous texture—unchanging instrumentation, register, or thematic material provides no boundary signals. Contrast creates articulation.",
            solutions: [
                "Textural contrast — Change density, register, or voicing at boundaries",
                "Thematic return — Reintroduce opening material to signal new section",
                "Register shift — Move to different octave or tessitura",
                "Orchestration change — Alter instrumentation or timbre at section changes"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/texture/",
            omtTitle: "Texture",
            readings: [
                "Berry, Structural Functions in Music",
                "Caplin, Classical Form",
                "LaRue, Guidelines for Style Analysis"
            ]
        },
        
        "diag_form_predictable_conventional": {
            reframing: "If your goal is to avoid generic form templates, the issue may be excessive convention—the structure follows predictable patterns without deviation. Innovation comes from variation on norms.",
            solutions: [
                "Hybrid forms — Combine elements from different formal types",
                "Formal innovation — Deviate from expected proportions or orderings",
                "Truncation — Omit expected sections (e.g., skip development)",
                "Expansion — Extend or elaborate conventional sections unexpectedly"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/phrase-archetypes-unique-forms/",
            omtTitle: "Phrase Archetypes",
            readings: [
                "Caplin, Classical Form (formal functions)",
                "Hepokoski & Darcy, Elements of Sonata Theory",
                "Schmalfeldt, In the Process of Becoming"
            ]
        },
        
        "diag_form_predictable_surprises": {
            reframing: "If your goal is to add formal interest, the issue may be formal automation—the structure unfolds exactly as expected without deviations. Surprise and delay create engagement.",
            solutions: [
                "False recapitulation — Suggest return in the wrong key or too early",
                "Extended development — Delay the return longer than expected",
                "Formal subversion — Undercut or reinterpret formal conventions",
                "Unexpected modulation — Move to surprising keys at conventional moments"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/phrase-archetypes-unique-forms/",
            omtTitle: "Phrase Archetypes",
            readings: [
                "Hepokoski & Darcy, Elements of Sonata Theory (deformations)",
                "Schmalfeldt, In the Process of Becoming",
                "Rosen, Sonata Forms"
            ]
        },
        
        "diag_form_return_literal": {
            reframing: "If your goal is to make the return feel fresh, the issue may be mechanical repetition—exact recapitulation reduces impact. Return should feel familiar yet renewed.",
            solutions: [
                "Varied recapitulation — Change orchestration, register, or texture on return",
                "Reharmonization — Use different harmonies under returning melody",
                "Compression — Abbreviate the recapitulation relative to exposition",
                "Embellishment — Add ornamentation or counterpoint to familiar material"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/sonata-form/",
            omtTitle: "Sonata Form",
            readings: [
                "Hepokoski & Darcy, Elements of Sonata Theory",
                "Caplin, Classical Form",
                "Rosen, Sonata Forms"
            ]
        },
        
        "diag_form_return_resolution": {
            reframing: "If your goal is to create a satisfying formal arrival, the issue may be weak preparation—the return happens without sufficient buildup or expectation. Returns need dominant prolongation.",
            solutions: [
                "Dominant prolongation — Extend V or V7 before the return",
                "Retransition buildup — Create a passage of increasing tension before return",
                "Textural preparation — Thin texture before return to highlight its arrival",
                "Rhythmic intensification — Accelerate rhythm approaching the return"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/sonata-form/",
            omtTitle: "Sonata Form",
            readings: [
                "Caplin, Classical Form (retransition)",
                "Hepokoski & Darcy, Elements of Sonata Theory",
                "Rothstein, Phrase Rhythm in Tonal Music"
            ]
        },
        
        "diag_form_return_completion": {
            reframing: "If your goal is to create a sense of finality, the issue may be inconclusive ending—the piece doesn't provide sufficient closure or resolution. Endings need weight and certainty.",
            solutions: [
                "Coda addition — Add a closing section after the main structural close",
                "Plagal extension — Add IV-I motion after the final cadence",
                "Tonic prolongation — Sustain and elaborate the final tonic harmony",
                "Textural finality — Use full texture, registral extremes, or dynamic emphasis"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/formal-sections-in-general/",
            omtTitle: "Formal Sections in General",
            readings: [
                "Caplin, Classical Form (closing functions)",
                "Agawu, Playing with Signs (closure)",
                "Meyer, Explaining Music (implications)"
            ]
        },
        
        // ========================================
        // MULTIPLE/UNSURE DIAGNOSTICS
        // ========================================
        
        "diag_multiple_interconnected": {
            reframing: "When multiple compositional dimensions feel problematic at once, the issue may be interconnected—harmony, rhythm, texture, and form often influence each other. Addressing one parameter may improve others.",
            solutions: [
                "Hierarchical diagnosis — Address the most fundamental issue first (often harmony or form)",
                "Systematic isolation — Test each parameter independently to understand interactions",
                "Prioritize structure — Resolve large-scale formal issues before local details",
                "Consider dependencies — Some problems (e.g., texture) may resolve when others (e.g., voice leading) are fixed"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/chapter/intro-to-harmony/",
            omtTitle: "Introduction to Harmony",
            readings: [
                "Schoenberg, Fundamentals of Musical Composition",
                "Caplin, Classical Form",
                "Berry, Structural Functions in Music"
            ]
        },
        
        "diag_multiple_intuitive": {
            reframing: "When you sense something is wrong but can't name it, trust that perception—intuition often precedes theoretical understanding. Compositional awareness doesn't require technical vocabulary.",
            solutions: [
                "Comparative listening — Play similar passages from repertoire to identify what differs",
                "Trust instinct — Your ear is often right even when you can't explain why",
                "Systematic experimentation — Try small changes and listen for improvement",
                "Seek colleague feedback — Another musician's perspective can help articulate the issue"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/",
            omtTitle: "Open Music Theory",
            readings: [
                "Rothstein, Phrase Rhythm in Tonal Music",
                "Berry, Structural Functions in Music",
                "Meyer, Emotion and Meaning in Music"
            ]
        },
        
        "diag_multiple_holistic": {
            reframing: "When the issue concerns character, mood, or expressive effect rather than technical parameters, recognize that these are valid compositional criteria. Music communicates feeling, not just structure.",
            solutions: [
                "Articulation choices — Legato vs. staccato, accents, tenuto marks affect character",
                "Tempo and rubato — Pacing and flexibility shape emotional trajectory",
                "Dynamic shaping — Crescendo, diminuendo, terraced dynamics create drama",
                "Orchestration and timbre — Instrumentation choices convey mood and color",
                "Harmonic color — Modal mixture, extended harmonies, chromaticism affect expression"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/",
            omtTitle: "Open Music Theory",
            readings: [
                "Cone, Musical Form and Musical Performance",
                "Meyer, Emotion and Meaning in Music",
                "Agawu, Playing with Signs"
            ]
        },
        
        "diag_multiple_describe": {
            reframing: "Sometimes the best way to explore a compositional problem is through conversation rather than diagnostic trees. Verbal description can clarify thinking and reveal solutions.",
            solutions: [
                "Use Claude AI chat — Describe the issue in your own words for tailored guidance",
                "Articulate the feeling — Explain what you want vs. what you're hearing",
                "Describe listener response — How do you want listeners to react?",
                "Compare to models — Reference pieces that achieve what you're aiming for"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/",
            omtTitle: "Open Music Theory",
            readings: [
                "Schoenberg, Fundamentals of Musical Composition",
                "Cone, Musical Form and Musical Performance",
                "Meyer, Explaining Music"
            ]
        },
        
        "diag_placeholder": {
            reframing: "This diagnostic pathway is still under development. The compositional categories you've selected are valid, but detailed guidance for this specific issue isn't yet available in the tool.",
            solutions: [
                "Consider the structural level — Is this a local detail issue or a larger formal problem?",
                "Examine multiple parameters — Often what seems like one problem (melody, rhythm) is actually related to another (harmony, texture)",
                "Try alternative framings — The issue you're experiencing might be better approached from a different diagnostic angle",
                "Use the AI chat feature — Describe your specific situation for more tailored guidance"
            ],
            omtLink: "https://viva.pressbooks.pub/openmusictheory/",
            omtTitle: "Open Music Theory",
            readings: [
                "Schoenberg, Fundamentals of Musical Composition",
                "Caplin, Classical Form"
            ]
        }
    })
    
    // Initialize on load
    Component.onCompleted: {
        console.log("=== Composition Tutor Loaded ===")
        // Check for selection and extract info
        extractSelectionInfo()
        // Start with first question
        currentQuestion = questions["start"]
        questionHistory = ["start"]
    }
    
    // Main UI
    Rectangle {
        anchors.fill: parent
        color: ui.theme.backgroundPrimaryColor
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15
            
            // Header
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: ui.theme.backgroundSecondaryColor
                radius: 4
                border.width: 1
                border.color: ui.theme.strokeColor
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 5
                    
                    Text {
                        text: "Composition Tutor"
                        color: ui.theme.fontPrimaryColor
                        font.pixelSize: 22
                        font.bold: true
                    }
                    
                    Text {
                        text: selectionInfo !== "" ? selectionInfo : "No passage selected"
                        color: selectionInfo !== "" ? ui.theme.fontPrimaryColor : "#ff6b6b"
                        font.pixelSize: 14
                    }
                }
            }
            
            //Item { Layout.preferredHeight: 20 }
            
            // Content area (either questions or diagnostic)
            Rectangle {
                Layout.fillWidth: true
                //Layout.fillHeight: true
                Layout.preferredHeight: 600
                color: ui.theme.backgroundSecondaryColor
                radius: 4
                border.width: 1
                border.color: ui.theme.strokeColor
                
                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 20
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    
                    ColumnLayout {
                        width: parent.parent.width - 40
                        spacing: 20
                        
                        // Show either question or diagnostic
                        Loader {
                            Layout.fillWidth: true
                            sourceComponent: showingDiagnostic ? diagnosticComponent : questionComponent
                        }
                    }
                }
            }
            
            // Navigation buttons
            Rectangle {
                visible: currentQuestion && currentQuestion.id !== "start"
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                Layout.minimumHeight: 60
                color: ui.theme.backgroundSecondaryColor
                radius: 4
                border.width: 1
                border.color: ui.theme.strokeColor
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10
                    
                    MU.FlatButton {
                        text: "← Back"
                        enabled: questionHistory.length > 0
                        Layout.preferredWidth: 120
                        onClicked: goBack()
                    }

                    Item { Layout.fillWidth: true }

                    MU.FlatButton {
                        text: "Reset"
                        Layout.preferredWidth: 120
                        onClicked: resetTool()
                    }
                }
            }
        }
    }
    
    // Question display component
    Component {
        id: questionComponent
        
        ColumnLayout {
            spacing: 20
            width: parent.width
            
            Text {
                text: currentQuestion ? currentQuestion.text : ""
                color: ui.theme.fontPrimaryColor
                font.pixelSize: 20
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                textFormat: Text.PlainText
                
                // Enable text selection
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    cursorShape: Qt.IBeamCursor
                }
            }
            
            // Options for choice questions
            Repeater {
                model: currentQuestion && currentQuestion.type === "choice" ? currentQuestion.options : []
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 300
                    Layout.minimumHeight: 60
                    Layout.preferredHeight: contentCol.implicitHeight + 30
                    color: optionMouseArea.containsMouse ? ui.theme.strokeColorlight : ui.theme.buttonColor
                    border.color: ui.theme.strokeColor
                    border.width: 1
                    radius: 6
                    
                    MouseArea {
                        id: optionMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: selectOption(index)
                    }
                    
                    ColumnLayout {
                        id: contentCol
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 5
                        
                        Text {
                            text: modelData.text
                            color: ui.theme.fontPrimaryColor
                            font.pixelSize: 17
                            font.bold: modelData.subtitle === ""
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                        
                        Text {
                            text: modelData.subtitle
                            color: ui.theme.fontSecondaryColor
                            font.pixelSize: 14
                            visible: modelData.subtitle !== ""
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }
            }
            
            // Text input for freeform questions
            ColumnLayout {
                visible: currentQuestion && currentQuestion.type === "text_input"
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    height: 120
                    color: ui.theme.backgroundSecondaryColor
                    border.color: ui.theme.strokeColor
                    border.width: 1
                    radius: 4

                    TextArea {
                        id: freeformInput
                        anchors.fill: parent
                        anchors.margins: 10
                        color: ui.theme.fontPrimaryColor
                        wrapMode: TextArea.Wrap
                        selectByMouse: true
                        placeholderText: "Describe what feels wrong about this passage..."
                        background: Rectangle { color: "transparent" }
                    }
                }

                MU.FlatButton {
                    text: "Continue →"
                    accentButton: true
                    Layout.preferredWidth: 150
                    Layout.alignment: Qt.AlignRight
                    onClicked: submitFreeformAnswer()
                }
            }
            
            // Placeholder message
            Text {
                visible: currentQuestion && currentQuestion.type === "placeholder"
                text: currentQuestion ? currentQuestion.text : ""
                color: ui.theme.fontPrimaryColor
                font.pixelSize: 14
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            
            MU.FlatButton {
                visible: currentQuestion && currentQuestion.type === "placeholder"
                text: "Continue to Discussion"
                accentButton: true
                Layout.preferredWidth: 200
                onClicked: {
                    if (currentQuestion) {
                        generateDiagnostic(currentQuestion.next)
                    }
                }
            }
        }
    }
    
    // Diagnostic display component
    Component {
        id: diagnosticComponent
        
        ColumnLayout {
            spacing: 25
            width: parent.width
            
            // Section 1: Diagnostic Reframing
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10
                
                Text {
                    text: "DIAGNOSTIC REFRAMING"
                    color: ui.theme.accentColor
                    font.pixelSize: 16
                    font.bold: true
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 2
                    color: ui.theme.strokeColor
                }
                
                TextEdit {
                    text: diagnosticData ? diagnosticData.reframing : ""
                    color: ui.theme.fontPrimaryColor
                    font.pixelSize: 16
                    wrapMode: TextEdit.WordWrap
                    Layout.fillWidth: true
                    readOnly: true
                    selectByMouse: true
                    textFormat: TextEdit.PlainText
                }
            }
            
            // Section 2: Solution Spaces
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10
                
                Text {
                    text: "SOLUTION SPACES TO CONSIDER"
                    color: ui.theme.accentColor
                    font.pixelSize: 16
                    font.bold: true
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 2
                    color: ui.theme.strokeColor
                }
                
                Repeater {
                    model: diagnosticData ? diagnosticData.solutions : []
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        
                        Text {
                            text: "•"
                            color: ui.theme.accentColor
                            font.pixelSize: 16
                            Layout.alignment: Qt.AlignTop
                        }
                        
                        TextEdit {
                            text: modelData
                            color: ui.theme.fontPrimaryColor
                            font.pixelSize: 15
                            wrapMode: TextEdit.WordWrap
                            Layout.fillWidth: true
                            readOnly: true
                            selectByMouse: true
                            textFormat: TextEdit.PlainText
                        }
                    }
                }
            }
            
            // Section 3: Learning Resources
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 15
                
                Text {
                    text: "LEARN MORE"
                    color: ui.theme.accentColor
                    font.pixelSize: 16
                    font.bold: true
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 2
                    color: ui.theme.strokeColor
                }
                
                // OpenMusicTheory link
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    color: linkMouseArea.containsMouse ? ui.theme.strokeColorlight : ui.theme.buttonColor
                    border.color: ui.theme.accentColor
                    border.width: 1
                    radius: 4
                    
                    MouseArea {
                        id: linkMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (diagnosticData && diagnosticData.omtLink) {
                                Qt.openUrlExternally(diagnosticData.omtLink)
                            }
                        }
                    }
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10
                        
                        Text {
                            text: "📖"
                            font.pixelSize: 26
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            
                            Text {
                                text: "OpenMusicTheory: " + (diagnosticData ? diagnosticData.omtTitle : "")
                                color: ui.theme.fontPrimaryColor
                                font.pixelSize: 17
                                font.bold: true
                            }
                            
                            Text {
                                text: "Click to open in browser"
                                color: ui.theme.fontSecondaryColor
                                font.pixelSize: 15
                            }
                        }
                    }
                }
                
                // Recommended readings
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Text {
                        text: "📚 Recommended Reading:"
                        color: ui.theme.fontPrimaryColor
                        font.pixelSize: 17
                        font.bold: true
                    }
                    
                    Repeater {
                        model: diagnosticData ? diagnosticData.readings : []
                        
                        TextEdit {
                            text: "   • " + modelData
                            color: ui.theme.fontPrimaryColor
                            font.pixelSize: 14
                            wrapMode: TextEdit.WordWrap
                            Layout.fillWidth: true
                            readOnly: true
                            selectByMouse: true
                            textFormat: TextEdit.PlainText
                        }
                    }
                }
                
                // Claude AI discussion button
                MU.FlatButton {
                    text: "💬 Discuss with Claude AI"
                    accentButton: true
                    Layout.preferredWidth: 250
                    Layout.alignment: Qt.AlignHCenter
                    onClicked: openClaudeDiscussion()
                }
            }
        }
    }
    
    // Functions
    
    function extractSelectionInfo() {
        if (!curScore) {
            selectionInfo = "No score open"
            return
        }
        
        var selection = curScore.selection
        if (!selection || !selection.elements || selection.elements.length === 0) {
            selectionInfo = "No passage selected - select measures before using this tool"
            return
        }
        
        // Get selection range info
        var cursor = curScore.newCursor()
        cursor.rewind(1) // Start of selection
        
        if (!cursor.segment) {
            selectionInfo = "No range selection detected"
            return
        }
        
        var startMeasure = cursor.measure ? cursor.measure.no + 1 : "?"
        var startStaff = cursor.staffIdx + 1

        cursor.rewind(2) // End of selection
        var endMeasure = cursor.measure ? cursor.measure.no + 1 : startMeasure
        var endStaff = cursor.staffIdx + 1

        // Build staff string — handle multi-staff selections
        var staffStr
        if (startStaff === endStaff) {
            staffStr = "Staff " + startStaff
        } else {
            staffStr = "Staves " + startStaff + "-" + endStaff
        }

        if (startMeasure === endMeasure) {
            selectionInfo = "Selected: Measure " + startMeasure + ", " + staffStr
        } else {
            selectionInfo = "Selected: Measures " + startMeasure + "-" + endMeasure + ", " + staffStr
        }
    }
    
    function selectOption(optionIndex) {
        if (!currentQuestion || !currentQuestion.options) return
        
        var option = currentQuestion.options[optionIndex]
        var nextId = option.next
        
        // Record this choice
        answerHistory.push({
            question: currentQuestion.text,
            answer: option.text
        })
        
        // Check if next is a diagnostic endpoint
        if (nextId.startsWith("diag_")) {
            generateDiagnostic(nextId)
        } else if (questions[nextId]) {
            currentQuestion = questions[nextId]
            // Only add to history if it's NOT a diagnostic-type question
            // (diagnostic-type questions auto-advance, so they shouldn't be in history)
            if (questions[nextId].type !== "diagnostic") {
                questionHistory.push(nextId)
            }
        } else {
            console.log("Error: Unknown next question ID: " + nextId)
        }
    }
    
    function submitFreeformAnswer() {
        var userText = freeformInput.text.trim()
        if (userText === "") {
            return
        }
        
        answerHistory.push({
            question: currentQuestion.text,
            answer: userText
        })
        
        // Navigate to diagnostic
        if (currentQuestion.next) {
            generateDiagnostic(currentQuestion.next)
        }
    }
    
    function generateDiagnostic(diagId) {
        if (diagnostics[diagId]) {
            diagnosticData = diagnostics[diagId]
            showingDiagnostic = true
        } else {
            console.log("Error: Unknown diagnostic ID: " + diagId)
        }
    }
    
    function goBack() {
        if (showingDiagnostic) {
            // Go back from diagnostic to last question
            showingDiagnostic = false
            diagnosticData = null
            
            // Skip backwards over any diagnostic-type questions (they auto-advance)
            while (questionHistory.length > 0) {
                var lastQuestionId = questionHistory[questionHistory.length - 1]
                if (questions[lastQuestionId] && questions[lastQuestionId].type === "diagnostic") {
                    // This is an intermediate diagnostic question, skip it
                    questionHistory.pop()
                    if (answerHistory.length > 0) {
                        answerHistory.pop()
                    }
                } else {
                    // Found a regular question, go back to it
                    if (questions[lastQuestionId]) {
                        currentQuestion = questions[lastQuestionId]
                    }
                    break
                }
            }
            return
        }
        if (questionHistory.length > 1) {
            questionHistory.pop()
            if (answerHistory.length > 0) {
                answerHistory.pop()
            }
            var previousId = questionHistory[questionHistory.length - 1]
            if (questions[previousId]) {
                currentQuestion = questions[previousId]
            }
        }
    }
    
    function resetTool() {
        currentQuestion = questions["start"]
        questionHistory = ["start"]
        answerHistory = []
        showingDiagnostic = false
        diagnosticData = null
        extractSelectionInfo()
    }
    
    function openClaudeDiscussion() {
        // Build context for Claude
        var context = "I'm working on a passage in my musical score"
        
        if (selectionInfo !== "" && selectionInfo !== "No passage selected - select measures before using this tool") {
            context += " (" + selectionInfo + ")"
        }
        
        context += ". The Composition Tutor diagnostic tool helped me identify the issue:\n\n"
        
        // Add diagnostic path
        context += "My diagnostic path:\n"
        for (var i = 0; i < answerHistory.length; i++) {
            context += "Q: " + answerHistory[i].question + "\n"
            context += "A: " + answerHistory[i].answer + "\n\n"
        }
        
        // Add diagnostic summary
        if (diagnosticData) {
            context += "Diagnostic summary:\n"
            context += diagnosticData.reframing + "\n\n"
            context += "Suggested approaches:\n"
            for (var j = 0; j < diagnosticData.solutions.length; j++) {
                context += "• " + diagnosticData.solutions[j] + "\n"
            }
        }
        
        context += "\n\nCan you help me think through this compositional problem?"
        
        // URL encode the context
        var encodedContext = encodeURIComponent(context)
        
        // Open Claude with pre-filled message
        var claudeUrl = "https://claude.ai/new?q=" + encodedContext
        Qt.openUrlExternally(claudeUrl)
    }
}
