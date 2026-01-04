# 📄 INSTRUCTIONS.md

## 🔄 Workflow Overview
This system is designed for atomic, living documentation that scales with team size while maintaining simplicity. Here's how it works:

### 🧑‍💻 For @eric (Human Operator)
1. **Daily Sessions:**  
   - Create a new file in `docs/SESSIONS/YYYY-MM-DD_instructions.md`  
   - Write unstructured, wordy instructions in natural language  

2. **Task Handoff:**  
   - @echo will parse these instructions into structured tasks in `docs/ECHO.md`  
   - @echo will tag tasks with technical categories (e.g., `[ARM64]`, `[DOC]`, `[TEST]`)  

---

### 🤖 For @echo (LLM Interpreter)
1. **Parsing Rules:**  
   - Convert messy instructions into a clean, prioritized task list in `docs/ECHO.md`  
   - Use consistent tags for task categorization  
   - Maintain parallel structure with original instructions for traceability  

2. **Auto-Generated Content:**  
   - Populate `docs/STATUS_REPORT.md` with technical notes, file references, and progress tracking  

---

### 🛠️ For @atlas (Engineer)
1. **Daily Updates:**  
   - Check `docs/ECHO.md` for new tasks and tag them with `[X]` when completed  
   - Update `docs/STATUS_REPORT.md` with:  
     - ✅ Task progress (checkboxes)  
     - 📝 Technical validation notes  
     - 📁 File references (e.g., `CMakeLists.txt`, `.github/workflows/build.yml`)  

2. **Session Management:**  
   - Ensure all work is traceable to a specific `SESSIONS/YYYY-MM-DD_instructions.md` file  

---

### 📁 File Structure
