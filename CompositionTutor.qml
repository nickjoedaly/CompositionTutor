import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import MuseScore 3.0

MuseScore {
    version: "1.0"
    title: "Composition Tutor"
    description: "Guided diagnostic tool for compositional problem-solving"
    categoryCode: "composing-arranging-tools"
    pluginType: "dialog"
    
    width: 900
    height: 850
    
    // Make dialog resizable
    property bool requiresResize: true
    
    // Custom button component since StyledButton isn't available
    Component {
        id: customButton
        
        Rectangle {
            property string text: ""
            property bool enabled: true
            signal clicked()
            
            id: buttonRect
            height: 40
            color: enabled ? (buttonMouseArea.containsMouse ? "#4a9eff" : "#3a7acc") : "#555555"
            radius: 6
            border.color: enabled ? "#5aafff" : "#666666"
            border.width: 1
            
            Text {
                anchors.centerIn: parent
                text: buttonRect.text
                color: buttonRect.enabled ? "#ffffff" : "#999999"
                font.pixelSize: 14
                font.bold: false
            }
            
            MouseArea {
                id: buttonMouseArea
                anchors.fill: parent
                hoverEnabled: true
                enabled: buttonRect.enabled
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: buttonRect.clicked()
            }
        }
    }
    
    // State variables
    property var currentQuestion: null
    property var questionHistory: []
    property var answerHistory: []
    property string selectionInfo: ""
    property bool showingDiagnostic: false
    property var diagnosticData: null
    
    // Question tree structure
    property var questions: ({
        "start": {
            id: "start",
            text: "What feels off about this passage?",
            type: "choice",
            options: [
                { text: "Harmony", subtitle: "chord progression, voice leading", next: "harmony_1" },
                { text: "Melody", subtitle: "contour, direction, intervallic content", next: "placeholder" },
                { text: "Texture", subtitle: "density, register, spacing", next: "placeholder" },
                { text: "Rhythm", subtitle: "momentum, organization, pacing", next: "placeholder" },
                { text: "Form", subtitle: "proportion, placement, balance", next: "placeholder" },
                { text: "Multiple / Unsure", subtitle: "", next: "placeholder" }
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
        color: "#2e2e2e"
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15
            
            // Header
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: "#3a3a3a"
                radius: 4
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 5
                    
                    Text {
                        text: "Composition Tutor"
                        color: "#ffffff"
                        font.pixelSize: 20
                        font.bold: true
                    }
                    
                    Text {
                        text: selectionInfo !== "" ? selectionInfo : "No passage selected"
                        color: selectionInfo !== "" ? "#b0b0b0" : "#ff6b6b"
                        font.pixelSize: 12
                    }
                }
            }
            
            Item { Layout.preferredHeight: 20 }
            
            // Content area (either questions or diagnostic)
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#252525"
                radius: 4
                
                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 20
                    clip: true
                    
                    ColumnLayout {
                        width: parent.width - 40
                        spacing: 20
                        
                        // Show either question or diagnostic
                        Loader {
                            Layout.fillWidth: true
                            sourceComponent: showingDiagnostic ? diagnosticComponent : questionComponent
                        }
                    }
                }
            }
            
            Item { Layout.preferredHeight: 15 }
            
            // Navigation buttons
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                color: "#3a3a3a"
                radius: 4
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10
                    
                    Loader {
                        sourceComponent: customButton
                        Layout.preferredWidth: 120
                        onLoaded: {
                            item.text = "← Back"
                            item.enabled = Qt.binding(function() { 
                                return questionHistory.length > 0
                            })
                            item.clicked.connect(goBack)
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Loader {
                        sourceComponent: customButton
                        Layout.preferredWidth: 120
                        onLoaded: {
                            item.text = "Reset"
                            item.clicked.connect(resetTool)
                        }
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
            
            Text {
                text: currentQuestion ? currentQuestion.text : ""
                color: "#ffffff"
                font.pixelSize: 18
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            
            // Options for choice questions
            Repeater {
                model: currentQuestion && currentQuestion.type === "choice" ? currentQuestion.options : []
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: modelData.subtitle !== "" ? 70 : 50
                    color: optionMouseArea.containsMouse ? "#404040" : "#353535"
                    border.color: "#4a4a4a"
                    border.width: 1
                    radius: 4
                    
                    MouseArea {
                        id: optionMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: selectOption(index)
                    }
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 3
                        
                        Text {
                            text: modelData.text
                            color: "#ffffff"
                            font.pixelSize: 15
                            font.bold: modelData.subtitle === ""
                        }
                        
                        Text {
                            text: modelData.subtitle
                            color: "#a0a0a0"
                            font.pixelSize: 12
                            visible: modelData.subtitle !== ""
                        }
                    }
                }
            }
            
            // Text input for freeform questions
            Column {
                visible: currentQuestion && currentQuestion.type === "text_input"
                Layout.fillWidth: true
                spacing: 10
                
                Rectangle {
                    width: parent.width
                    height: 120
                    color: "#353535"
                    border.color: "#4a4a4a"
                    border.width: 1
                    radius: 4
                    
                    TextArea {
                        id: freeformInput
                        anchors.fill: parent
                        anchors.margins: 10
                        color: "#ffffff"
                        wrapMode: TextArea.Wrap
                        placeholderText: "Describe what feels wrong about this passage..."
                        background: Rectangle { color: "transparent" }
                    }
                }
                
                Loader {
                    sourceComponent: customButton
                    width: 150
                    anchors.right: parent.right
                    onLoaded: {
                        item.text = "Continue →"
                        item.clicked.connect(submitFreeformAnswer)
                    }
                }
            }
            
            // Placeholder message
            Text {
                visible: currentQuestion && currentQuestion.type === "placeholder"
                text: currentQuestion ? currentQuestion.text : ""
                color: "#ffaa00"
                font.pixelSize: 14
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            
            Loader {
                visible: currentQuestion && currentQuestion.type === "placeholder"
                sourceComponent: customButton
                Layout.preferredWidth: 200
                onLoaded: {
                    item.text = "Continue to Discussion"
                    item.clicked.connect(function() {
                        if (currentQuestion) {
                            generateDiagnostic(currentQuestion.next)
                        }
                    })
                }
            }
        }
    }
    
    // Diagnostic display component
    Component {
        id: diagnosticComponent
        
        ColumnLayout {
            spacing: 25
            
            // Section 1: Diagnostic Reframing
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10
                
                Text {
                    text: "DIAGNOSTIC REFRAMING"
                    color: "#4a9eff"
                    font.pixelSize: 14
                    font.bold: true
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 2
                    color: "#4a4a4a"
                }
                
                Text {
                    text: diagnosticData ? diagnosticData.reframing : ""
                    color: "#e0e0e0"
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    lineHeight: 1.4
                }
            }
            
            // Section 2: Solution Spaces
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10
                
                Text {
                    text: "SOLUTION SPACES TO CONSIDER"
                    color: "#4a9eff"
                    font.pixelSize: 14
                    font.bold: true
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 2
                    color: "#4a4a4a"
                }
                
                Repeater {
                    model: diagnosticData ? diagnosticData.solutions : []
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        
                        Text {
                            text: "•"
                            color: "#4a9eff"
                            font.pixelSize: 16
                            Layout.alignment: Qt.AlignTop
                        }
                        
                        Text {
                            text: modelData
                            color: "#e0e0e0"
                            font.pixelSize: 13
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            lineHeight: 1.4
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
                    color: "#4a9eff"
                    font.pixelSize: 14
                    font.bold: true
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 2
                    color: "#4a4a4a"
                }
                
                // OpenMusicTheory link
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    color: linkMouseArea.containsMouse ? "#404040" : "#353535"
                    border.color: "#4a9eff"
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
                            font.pixelSize: 24
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            
                            Text {
                                text: "OpenMusicTheory: " + (diagnosticData ? diagnosticData.omtTitle : "")
                                color: "#ffffff"
                                font.pixelSize: 13
                                font.bold: true
                            }
                            
                            Text {
                                text: "Click to open in browser"
                                color: "#a0a0a0"
                                font.pixelSize: 11
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
                        color: "#e0e0e0"
                        font.pixelSize: 13
                        font.bold: true
                    }
                    
                    Repeater {
                        model: diagnosticData ? diagnosticData.readings : []
                        
                        Text {
                            text: "   • " + modelData
                            color: "#d0d0d0"
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }
                
                // Claude AI discussion button
                Loader {
                    sourceComponent: customButton
                    Layout.preferredWidth: 250
                    Layout.alignment: Qt.AlignHCenter
                    onLoaded: {
                        item.text = "💬 Discuss with Claude AI"
                        item.clicked.connect(openClaudeDiscussion)
                    }
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
        var staff = cursor.staffIdx + 1
        
        cursor.rewind(2) // End of selection
        var endMeasure = cursor.measure ? cursor.measure.no + 1 : startMeasure
        
        if (startMeasure === endMeasure) {
            selectionInfo = "Selected: Measure " + startMeasure + ", Staff " + staff
        } else {
            selectionInfo = "Selected: Measures " + startMeasure + "-" + endMeasure + ", Staff " + staff
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
            questionHistory.push(nextId)
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
            if (questionHistory.length > 0) {
                var lastQuestionId = questionHistory[questionHistory.length - 1]
                if (questions[lastQuestionId]) {
                    currentQuestion = questions[lastQuestionId]
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
