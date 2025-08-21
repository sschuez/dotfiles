# Refactoring UI — Expanded Design Principles

## 1. Layout & Spacing
- **Rule:** Establish a consistent spacing scale (e.g. multiples of 4 or 8px) and apply it uniformly across margins, paddings, and gaps.  
  **Rationale:** Predictable spacing creates rhythm, reduces visual noise, and makes layouts easier to scan.  
- **Rule:** Group related items close together; separate unrelated items with whitespace.  
  **Rationale:** Proximity is a key Gestalt principle that conveys relationship.  
- **Rule:** Align elements to a grid or baseline system; avoid arbitrary placement.  
  **Rationale:** Alignment creates structure and helps users predict content flow.  
- **Rule:** Favor generous whitespace over tight packing.  
  **Rationale:** Breathing room increases comprehension and reduces cognitive load.  

## 2. Typography
- **Rule:** Limit typefaces to 1–2 families; use weight, size, and style variations to establish hierarchy.  
  **Rationale:** Too many typefaces fragment the design; hierarchy is better conveyed through contrast in size and weight.  
- **Rule:** Use no more than 3–4 font sizes across an interface (e.g. body, small, heading, subheading).  
  **Rationale:** Excessive variation creates inconsistency and noise.  
- **Rule:** Apply sufficient line-height (1.4–1.6× font size for body text).  
  **Rationale:** Good leading improves readability, especially on screens.  
- **Rule:** Use consistent letter-spacing (tracking); avoid arbitrary kerning adjustments unless for logos.  

## 3. Color & Contrast
- **Rule:** Start with a neutral base (grays, off-whites) and layer 1–2 accent colors.  
  **Rationale:** Neutrals provide flexibility; accents provide focus.  
- **Rule:** Assign colors semantic roles (e.g. green = success, red = error, blue = primary action).  
  **Rationale:** Semantic mapping improves recognition and reduces ambiguity.  
- **Rule:** Ensure minimum contrast ratio (WCAG AA: 4.5:1 for text) for accessibility.  
  **Rationale:** Contrast guarantees legibility across devices and conditions.  
- **Rule:** Test designs in grayscale to verify that contrast alone (not hue) conveys hierarchy.  

## 4. Visual Hierarchy
- **Rule:** Make the most important element visually dominant (size, weight, color, or placement).  
  **Rationale:** Users scan quickly; clear hierarchy reduces time to find what matters.  
- **Rule:** Avoid equal visual weight for unrelated elements.  
  **Rationale:** Uniform emphasis causes confusion and dilutes focus.  
- **Rule:** Establish hierarchy using progressive steps (e.g. H1 > H2 > body) rather than arbitrary jumps.  

## 5. Components & Elements
- **Buttons:**  
  - **Rule:** Use one distinct “primary” button style per view.  
  - **Rule:** Use secondary/tertiary styles for less important actions.  
  - **Rationale:** This makes the intended next step obvious.  
- **Forms:**  
  - **Rule:** Use clear labels above fields, never placeholders alone.  
  - **Rule:** Group related inputs (e.g. address fields) into sections.  
  - **Rule:** Keep forms short; remove non-essential fields.  
  - **Rationale:** Forms are friction points; clarity and brevity reduce abandonment.  
- **Cards & Containers:**  
  - **Rule:** Separate sections with subtle borders, shadows, or whitespace (not all at once).  
  - **Rationale:** Over-separation causes clutter; subtle cues maintain cohesion.  
- **Icons:**  
  - **Rule:** Use icons consistently (stroke vs. filled, size, weight).  
  - **Rule:** Pair icons with labels unless meaning is universally obvious.  
  - **Rationale:** Icons without text are often ambiguous.  

## 6. Imagery & Illustration
- **Rule:** Maintain consistent aspect ratios and image dimensions across lists or grids.  
  **Rationale:** Consistency avoids jarring shifts in alignment.  
- **Rule:** Use imagery with a coherent visual style (color treatment, line weight, tone).  
  **Rationale:** Mixed styles undermine trust and professionalism.  
- **Rule:** Crop images to highlight the subject, not background.  

## 7. Feedback & State
- **Rule:** Every interactive element must have visible states: default, hover, active, focus, disabled, and loading.  
  **Rationale:** State feedback assures users the system is responding.  
- **Rule:** Show progress indicators (spinners, bars) for operations taking >500ms.  
  **Rationale:** Users interpret lack of feedback as failure.  
- **Rule:** Design meaningful empty states (e.g. “No items yet — add one”).  
  **Rationale:** Empty states guide users rather than showing a blank screen.  
- **Rule:** Provide clear error states with instructions to recover.  

## 8. Consistency & Systems
- **Rule:** Reuse established design patterns instead of inventing new ones for common interactions.  
  **Rationale:** Familiarity reduces learning curve.  
- **Rule:** Build a small design system: spacing scale, color tokens, typography rules, component library.  
  **Rationale:** Consistency scales across a growing product.  
- **Rule:** Prioritize predictability; users should be able to guess how an element behaves.  
  **Rationale:** Predictable systems reduce user hesitation and errors.  
