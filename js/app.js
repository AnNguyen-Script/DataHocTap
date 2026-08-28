/**
 * EduVault - Main Academic Controller
 * Orchestrates Study Drive, Markdown Notes, Exam Bank, Global Search, and GitHub Synchronization.
 */

document.addEventListener('DOMContentLoaded', () => {
  const api = new GitHubAPI();
  const storage = new StorageManager();

  // State
  let config = storage.getConfig();
  let currentPath = '';
  let currentItems = [];
  let currentSubjectFilter = 'all';
  let currentCategoryFilter = 'all';
  let currentEditingFile = null;
  let examRecords = [];
  let examFileSha = null;
  let viewMode = 'grid'; // 'grid' | 'list'

  // Notes State
  let currentNoteFile = null;

  // DOM - Header & Navigation
  const moduleTabs = document.querySelectorAll('.module-tab');
  const tabContents = document.querySelectorAll('.tab-content');
  const globalSearchInput = document.getElementById('global-search-input');
  const headerRepoText = document.getElementById('header-repo-text');
  const btnRefresh = document.getElementById('btn-refresh');
  const btnOpenSettings = document.getElementById('btn-open-settings');
  const subjectPills = document.querySelectorAll('.subject-pill');
  const btnAddSubjectPill = document.getElementById('btn-add-subject-pill');

  // DOM - Tab 1: Study Drive
  const bcRoot = document.getElementById('bc-root');
  const bcTrail = document.getElementById('bc-trail');
  const fileCategoryFilter = document.getElementById('file-category-filter');
  const btnViewGrid = document.getElementById('btn-view-grid');
  const btnViewList = document.getElementById('btn-view-list');
  const btnNewStudyFolder = document.getElementById('btn-new-study-folder');
  const btnTriggerUpload = document.getElementById('btn-trigger-upload');
  const btnBrowseClick = document.getElementById('btn-browse-click');
  const btnEmptyUploadAction = document.getElementById('btn-empty-upload-action');
  const hiddenFileInput = document.getElementById('hidden-file-input');
  const studyDropzone = document.getElementById('study-dropzone');
  const uploadProgressBox = document.getElementById('upload-progress-box');
  const upFilename = document.getElementById('up-filename');
  const upPercentage = document.getElementById('up-percentage');
  const upFill = document.getElementById('up-fill');
  const studyFileGrid = document.getElementById('study-file-grid');
  const studyEmpty = document.getElementById('study-empty');
  const studyLoading = document.getElementById('study-loading');

  // DOM - Tab 2: Notes
  const notesListContainer = document.getElementById('notes-list-container');
  const btnCreateNote = document.getElementById('btn-create-note');
  const noteTitleInput = document.getElementById('note-title-input');
  const noteSaveStatus = document.getElementById('note-save-status');
  const btnNoteSplit = document.getElementById('btn-note-split');
  const btnNoteEditOnly = document.getElementById('btn-note-edit-only');
  const btnNotePreviewOnly = document.getElementById('btn-note-preview-only');
  const notePanelsContainer = document.getElementById('note-panels-container');
  const noteMarkdownTextarea = document.getElementById('note-markdown-textarea');
  const markdownRenderedBody = document.getElementById('markdown-rendered-body');
  const btnSaveNoteGithub = document.getElementById('btn-save-note-github');

  // DOM - Tab 3: Exam Bank
  const btnOpenAddExamModal = document.getElementById('btn-open-add-exam-modal');
  const btnExportExamData = document.getElementById('btn-export-exam-data');
  const examSearchInput = document.getElementById('exam-search-input');
  const examStatusSummary = document.getElementById('exam-status-summary');
  const examsTableBody = document.getElementById('exams-table-body');
  const emptyExamState = document.getElementById('empty-exam-state');

  // DOM - Modals
  const modalSettings = document.getElementById('modal-settings');
  const btnCloseSettings = document.getElementById('btn-close-settings');
  const cfgOwner = document.getElementById('cfg-owner');
  const cfgRepo = document.getElementById('cfg-repo');
  const cfgBranch = document.getElementById('cfg-branch');
  const cfgToken = document.getElementById('cfg-token');
  const btnToggleCfgToken = document.getElementById('btn-toggle-cfg-token');
  const btnTestCfg = document.getElementById('btn-test-cfg');
  const btnSaveCfg = document.getElementById('btn-save-cfg');
  const cfgFeedback = document.getElementById('cfg-feedback');

  const modalViewer = document.getElementById('modal-viewer');
  const btnCloseViewer = document.getElementById('btn-close-viewer');
  const viewerFileName = document.getElementById('viewer-file-name');
  const viewerFileIcon = document.getElementById('viewer-file-icon');
  const viewerBodyContent = document.getElementById('viewer-body-content');
  const viewerFoot = document.getElementById('viewer-foot');
  const btnViewerCopyCdn = document.getElementById('btn-viewer-copy-cdn');
  const btnViewerDownload = document.getElementById('btn-viewer-download');
  const btnViewerDelete = document.getElementById('btn-viewer-delete');
  const btnViewerSaveChanges = document.getElementById('btn-viewer-save-changes');

  const modalFolder = document.getElementById('modal-folder');
  const btnCloseFolder = document.getElementById('btn-close-folder');
  const btnCancelFolder = document.getElementById('btn-cancel-folder');
  const inputNewFolderName = document.getElementById('input-new-folder-name');
  const btnConfirmFolder = document.getElementById('btn-confirm-folder');

  const modalExam = document.getElementById('modal-exam');
  const btnCloseExam = document.getElementById('btn-close-exam');
  const btnCancelExam = document.getElementById('btn-cancel-exam');
  const examEditId = document.getElementById('exam-edit-id');
  const examInTitle = document.getElementById('exam-in-title');
  const examInSubject = document.getElementById('exam-in-subject');
  const examInTerm = document.getElementById('exam-in-term');
  const examInDifficulty = document.getElementById('exam-in-difficulty');
  const examInStatus = document.getElementById('exam-in-status');
  const examInLink = document.getElementById('exam-in-link');
  const btnSaveExam = document.getElementById('btn-save-exam');

  const toastHub = document.getElementById('toast-hub');

  // ==========================================================================
  // Toast Helper
  // ==========================================================================
  function showToast(message, type = 'info', duration = 3000) {
    const toast = document.createElement('div');
    toast.className = `toast-msg ${type}`;
    let icon = 'fa-solid fa-circle-info';
    if (type === 'success') icon = 'fa-solid fa-circle-check';
    if (type === 'error') icon = 'fa-solid fa-triangle-exclamation';

    toast.innerHTML = `<i class="${icon}"></i> <span>${message}</span>`;
    toastHub.appendChild(toast);

    setTimeout(() => {
      toast.style.opacity = '0';
      toast.style.transform = 'translateY(10px)';
      toast.style.transition = 'all 0.3s ease';
      setTimeout(() => toast.remove(), 300);
    }, duration);
  }

  // ==========================================================================
  // Global Shortcut: Ctrl + K Search
  // ==========================================================================
  window.addEventListener('keydown', (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') {
      e.preventDefault();
      globalSearchInput.focus();
    }
  });

  // ==========================================================================
  // Module Tab Switching
  // ==========================================================================
  moduleTabs.forEach(tab => {
    tab.addEventListener('click', () => {
      moduleTabs.forEach(t => t.classList.remove('active'));
      tabContents.forEach(c => c.classList.remove('active'));

      tab.classList.add('active');
      const target = document.getElementById(tab.dataset.tab);
      if (target) target.classList.add('active');

      if (tab.dataset.tab === 'tab-study-notes') loadNotesList();
      if (tab.dataset.tab === 'tab-exam-bank') loadExamsData();
    });
  });

  // ==========================================================================
  // Subject Pills Filtering
  // ==========================================================================
  subjectPills.forEach(pill => {
    pill.addEventListener('click', () => {
      document.querySelectorAll('.subject-pill').forEach(p => p.classList.remove('active'));
      pill.classList.add('active');
      currentSubjectFilter = pill.dataset.subject;
      applyFilters();
    });
  });

  btnAddSubjectPill.addEventListener('click', () => {
    const name = prompt('Nhập tên môn học mới (Ví dụ: HoaHoc, LichSu, TrietHoc):');
    if (name) {
      const cleanName = name.replace(/\s+/g, '');
      const btn = document.createElement('button');
      btn.className = 'subject-pill';
      btn.dataset.subject = cleanName;
      btn.textContent = `📖 ${name}`;
      btn.addEventListener('click', () => {
        document.querySelectorAll('.subject-pill').forEach(p => p.classList.remove('active'));
        btn.classList.add('active');
        currentSubjectFilter = cleanName;
        applyFilters();
      });
      document.getElementById('subject-pills-bar').insertBefore(btn, btnAddSubjectPill);
      btn.click();
    }
  });

  // ==========================================================================
  // TAB 1: Study Drive (Kho Tài Liệu Môn Học)
  // ==========================================================================
  async function loadDirectory(path = '') {
    currentPath = path;
    updateBreadcrumbs();
    studyFileGrid.innerHTML = '';
    studyEmpty.style.display = 'none';
    studyLoading.style.display = 'flex';

    try {
      const items = await api.getContents(config.owner, config.repo, currentPath, config.branch, config.token);
      currentItems = items || [];
      applyFilters();
    } catch (e) {
      showToast(`Không thể tải dữ liệu: ${e.message}`, 'error', 4000);
      studyEmpty.style.display = 'flex';
      studyEmpty.querySelector('h3').textContent = 'Lỗi kết nối Repository';
      studyEmpty.querySelector('p').textContent = e.message;
    } finally {
      studyLoading.style.display = 'none';
    }
  }

  // Danh sách các tệp mã nguồn của hệ thống website cần ẩn để không làm rối mắt
  const SYSTEM_SOURCE_FILES = [
    'index.html',
    'styles.css',
    'readme.md',
    'js',
    '.gitkeep',
    '.gitignore',
    'cname',
    'license',
    'package.json'
  ];

  function applyFilters() {
    let filtered = [...currentItems];

    // Tự động ẩn các tệp mã nguồn website khi ở thư mục gốc (Gốc)
    if (!currentPath) {
      filtered = filtered.filter(item => !SYSTEM_SOURCE_FILES.includes(item.name.toLowerCase()));
    }

    // Global Search filter
    const query = globalSearchInput.value.toLowerCase().trim();
    if (query) {
      filtered = filtered.filter(item => item.name.toLowerCase().includes(query));
    }

    // Subject Pill filter
    if (currentSubjectFilter !== 'all') {
      filtered = filtered.filter(item => 
        item.name.toLowerCase().includes(currentSubjectFilter.toLowerCase()) || 
        item.path.toLowerCase().includes(currentSubjectFilter.toLowerCase())
      );
    }

    // Category filter
    if (currentCategoryFilter !== 'all') {
      filtered = filtered.filter(item => {
        if (item.type === 'dir') return true;
        const info = storage.classifyStudyFile(item.name);
        return info.category === currentCategoryFilter;
      });
    }

    renderStudyFiles(filtered);
  }

  function renderStudyFiles(items) {
    studyFileGrid.innerHTML = '';

    if (!items || items.length === 0) {
      studyEmpty.style.display = 'flex';
      return;
    }

    studyEmpty.style.display = 'none';

    // Sort folders first
    const sorted = [...items].sort((a, b) => {
      if (a.type === b.type) return a.name.localeCompare(b.name);
      return a.type === 'dir' ? -1 : 1;
    });

    sorted.forEach(item => {
      const card = document.createElement('div');
      card.className = `study-card ${item.type === 'dir' ? 'folder' : ''}`;

      if (item.type === 'dir') {
        card.innerHTML = `
          <div class="card-top">
            <div class="card-icon-box" style="background: rgba(245, 158, 11, 0.15); color: var(--amber);">
              <i class="fa-solid fa-folder"></i>
            </div>
            <span class="badge-study-type type-folder">Thư mục môn</span>
          </div>
          <div class="card-filename" title="${item.name}">${item.name}</div>
          <div class="card-meta-row">
            <span>Danh mục học tập</span>
            <i class="fa-solid fa-arrow-right"></i>
          </div>
        `;
        card.addEventListener('click', () => loadDirectory(item.path));
      } else {
        const fileInfo = storage.classifyStudyFile(item.name);
        const sizeStr = storage.formatBytes(item.size);
        const cdnUrls = api.getPublicUrls(config.owner, config.repo, item.path, config.branch);

        card.innerHTML = `
          <div class="card-top">
            <div class="card-icon-box ${fileInfo.cssClass}">
              <i class="${fileInfo.icon}"></i>
            </div>
            <span class="badge-study-type ${fileInfo.cssClass}">${fileInfo.label}</span>
          </div>
          <div class="card-filename" title="${item.name}">${item.name}</div>
          <div class="card-meta-row">
            <span>${sizeStr}</span>
          </div>
          <div class="card-actions-quick">
            <button class="q-btn btn-copy-cdn-quick" title="Sao chép link CDN" data-url="${cdnUrls.jsdelivr}">
              <i class="fa-solid fa-bolt"></i>
            </button>
            <button class="q-btn btn-view-quick" title="Xem chi tiết">
              <i class="fa-regular fa-eye"></i>
            </button>
          </div>
        `;

        card.querySelector('.btn-copy-cdn-quick').addEventListener('click', (e) => {
          e.stopPropagation();
          navigator.clipboard.writeText(cdnUrls.jsdelivr);
          showToast(`Đã sao chép link tải CDN: ${item.name}`, 'success');
        });

        card.addEventListener('click', () => openViewerModal(item));
      }

      studyFileGrid.appendChild(card);
    });
  }

  // Breadcrumbs
  function updateBreadcrumbs() {
    bcTrail.innerHTML = '';
    if (!currentPath) {
      bcRoot.classList.add('active');
      return;
    }
    bcRoot.classList.remove('active');

    const parts = currentPath.split('/').filter(Boolean);
    let accum = '';
    parts.forEach((p, idx) => {
      accum += (idx === 0 ? '' : '/') + p;
      const target = accum;

      const sep = document.createElement('span');
      sep.className = 'bc-sep';
      sep.innerHTML = '<i class="fa-solid fa-chevron-right"></i>';
      bcTrail.appendChild(sep);

      const btn = document.createElement('button');
      btn.className = `bc-item ${idx === parts.length - 1 ? 'active' : ''}`;
      btn.textContent = p;
      btn.addEventListener('click', () => loadDirectory(target));
      bcTrail.appendChild(btn);
    });
  }

  bcRoot.addEventListener('click', () => loadDirectory(''));

  // Filter Listeners
  globalSearchInput.addEventListener('input', applyFilters);
  fileCategoryFilter.addEventListener('change', (e) => {
    currentCategoryFilter = e.target.value;
    applyFilters();
  });

  // View switch
  btnViewGrid.addEventListener('click', () => {
    btnViewGrid.classList.add('active');
    btnViewList.classList.remove('active');
    studyFileGrid.classList.remove('list-view');
  });

  btnViewList.addEventListener('click', () => {
    btnViewList.classList.add('active');
    btnViewGrid.classList.remove('active');
    studyFileGrid.classList.add('list-view');
  });

  // Drag & Drop Upload
  ['dragenter', 'dragover'].forEach(eName => {
    studyDropzone.addEventListener(eName, (e) => {
      e.preventDefault();
      studyDropzone.classList.add('dragover');
    });
  });

  ['dragleave', 'drop'].forEach(eName => {
    studyDropzone.addEventListener(eName, (e) => {
      e.preventDefault();
      studyDropzone.classList.remove('dragover');
    });
  });

  studyDropzone.addEventListener('drop', (e) => {
    const files = e.dataTransfer.files;
    if (files.length > 0) uploadFiles(Array.from(files));
  });

  btnTriggerUpload.addEventListener('click', () => hiddenFileInput.click());
  btnBrowseClick.addEventListener('click', () => hiddenFileInput.click());
  btnEmptyUploadAction.addEventListener('click', () => hiddenFileInput.click());

  hiddenFileInput.addEventListener('change', (e) => {
    if (e.target.files.length > 0) {
      uploadFiles(Array.from(e.target.files));
      hiddenFileInput.value = '';
    }
  });

  async function uploadFiles(files) {
    if (!config.token) {
      showToast('Cần có GitHub Token (PAT) trong Cấu Hình để tải tài liệu lên!', 'error', 4000);
      modalSettings.style.display = 'flex';
      return;
    }

    uploadProgressBox.style.display = 'block';
    const total = files.length;
    let done = 0;

    for (let i = 0; i < total; i++) {
      const file = files[i];
      const targetPath = currentPath ? `${currentPath}/${file.name}` : file.name;
      upFilename.textContent = `Đang tải (${i + 1}/${total}): ${file.name}`;
      const pct = Math.round(((i) / total) * 100);
      upFill.style.width = `${pct}%`;
      upPercentage.textContent = `${pct}%`;

      try {
        const b64 = await storage.fileToBase64(file);
        const existing = currentItems.find(it => it.name === file.name);
        const sha = existing ? existing.sha : null;

        await api.uploadFile(
          config.owner,
          config.repo,
          targetPath,
          b64,
          `EduVault: Lưu tài liệu ${file.name}`,
          sha,
          config.branch,
          config.token
        );
        done++;
        showToast(`Đã lưu thành công: ${file.name}`, 'success');
      } catch (err) {
        showToast(`Lỗi tải lên ${file.name}: ${err.message}`, 'error');
      }
    }

    upFill.style.width = '100%';
    upPercentage.textContent = '100%';
    setTimeout(() => {
      uploadProgressBox.style.display = 'none';
      upFill.style.width = '0%';
    }, 1200);

    loadDirectory(currentPath);
  }

  // Create Subject Folder
  btnNewStudyFolder.addEventListener('click', () => {
    if (!config.token) {
      showToast('Cần có GitHub Token để tạo thư mục môn học.', 'error');
      modalSettings.style.display = 'flex';
      return;
    }
    inputNewFolderName.value = '';
    modalFolder.style.display = 'flex';
    inputNewFolderName.focus();
  });

  btnCloseFolder.addEventListener('click', () => modalFolder.style.display = 'none');
  btnCancelFolder.addEventListener('click', () => modalFolder.style.display = 'none');

  btnConfirmFolder.addEventListener('click', async () => {
    const fName = inputNewFolderName.value.trim().replace(/[\\/:*?"<>|]/g, '');
    if (!fName) {
      showToast('Vui lòng nhập tên thư mục môn học hợp lệ.', 'error');
      return;
    }

    const folderPath = currentPath ? `${currentPath}/${fName}/.gitkeep` : `${fName}/.gitkeep`;
    try {
      modalFolder.style.display = 'none';
      showToast('Đang tạo thư mục môn học trên GitHub...', 'info');
      await api.uploadFile(
        config.owner,
        config.repo,
        folderPath,
        storage.utf8ToBase64('# EduVault Folder Placeholder'),
        `EduVault: Tạo thư mục ${fName}`,
        null,
        config.branch,
        config.token
      );
      showToast(`Đã tạo thư mục môn '${fName}'!`, 'success');
      loadDirectory(currentPath);
    } catch (err) {
      showToast(`Lỗi tạo thư mục: ${err.message}`, 'error');
    }
  });

  // Quick subject folder creators from empty state
  document.querySelectorAll('.btn-quick-add-folder').forEach(btn => {
    btn.addEventListener('click', () => {
      if (!config.token) {
        showToast('Cần có GitHub Token để tạo thư mục môn học.', 'error');
        modalSettings.style.display = 'flex';
        return;
      }
      inputNewFolderName.value = btn.getAttribute('data-name');
      modalFolder.style.display = 'flex';
      inputNewFolderName.focus();
    });
  });

  // ==========================================================================
  // TAB 2: Markdown Study Notes (Sổ Tay Ghi Chú)
  // ==========================================================================
  async function loadNotesList() {
    notesListContainer.innerHTML = '<div style="padding:1rem; text-align:center; font-size:0.75rem; color:var(--text-muted);"><i class="fa-solid fa-spinner fa-spin"></i> Đang tải ghi chú...</div>';

    try {
      // Check for notes in root or 'notes' directory
      let notes = await api.getContents(config.owner, config.repo, 'notes', config.branch, config.token).catch(() => []);
      if (notes.length === 0) {
        const rootItems = await api.getContents(config.owner, config.repo, '', config.branch, config.token);
        notes = rootItems.filter(it => it.name.endsWith('.md') && it.name !== 'README.md');
      }

      renderNotesList(notes);
    } catch (e) {
      notesListContainer.innerHTML = '<div style="padding:1rem; text-align:center; font-size:0.75rem; color:var(--rose);">Chưa có ghi chú nào.</div>';
    }
  }

  function renderNotesList(notes) {
    notesListContainer.innerHTML = '';
    if (!notes || notes.length === 0) {
      notesListContainer.innerHTML = '<div style="padding:1rem; text-align:center; font-size:0.75rem; color:var(--text-muted);">Chưa có ghi chú. Bấm nút (+) để tạo ghi chú mới.</div>';
      return;
    }

    notes.forEach((item, idx) => {
      const div = document.createElement('div');
      div.className = `note-item ${idx === 0 ? 'active' : ''}`;
      div.innerHTML = `
        <div class="note-item-title"><i class="fa-regular fa-file-lines text-mint"></i> ${item.name}</div>
        <div class="note-item-date">Tài liệu Markdown</div>
      `;
      div.addEventListener('click', () => {
        document.querySelectorAll('.note-item').forEach(n => n.classList.remove('active'));
        div.classList.add('active');
        openNote(item);
      });
      notesListContainer.appendChild(div);
    });

    if (notes.length > 0) openNote(notes[0]);
  }

  async function openNote(item) {
    currentNoteFile = item;
    noteTitleInput.value = item.name;
    noteSaveStatus.textContent = 'Đang tải...';

    try {
      const fileData = await api.getFileDetails(config.owner, config.repo, item.path, config.branch, config.token);
      currentNoteFile.sha = fileData.sha;
      const content = storage.base64ToUtf8(fileData.content || '');
      noteMarkdownTextarea.value = content;
      renderMarkdownPreview(content);
      noteSaveStatus.textContent = 'Đã đồng bộ';
    } catch (e) {
      noteSaveStatus.textContent = 'Lỗi đọc file';
    }
  }

  function renderMarkdownPreview(rawMd) {
    if (typeof marked !== 'undefined') {
      markdownRenderedBody.innerHTML = marked.parse(rawMd);
      if (window.hljs) {
        markdownRenderedBody.querySelectorAll('pre code').forEach(block => hljs.highlightElement(block));
      }
    }
  }

  noteMarkdownTextarea.addEventListener('input', () => {
    noteSaveStatus.textContent = 'Chưa lưu thay đổi';
    renderMarkdownPreview(noteMarkdownTextarea.value);
  });

  btnCreateNote.addEventListener('click', () => {
    const title = prompt('Nhập tên bài ghi chú (Ví dụ: GiaiTich_Chuong1.md):', 'GhiChuMoi.md');
    if (title) {
      const safeTitle = title.endsWith('.md') ? title : `${title}.md`;
      currentNoteFile = { name: safeTitle, path: `notes/${safeTitle}`, sha: null };
      noteTitleInput.value = safeTitle;
      noteMarkdownTextarea.value = `# ${safeTitle.replace('.md', '')}\n\n- Ghi chú lý thuyết tại đây...\n`;
      renderMarkdownPreview(noteMarkdownTextarea.value);
      noteSaveStatus.textContent = 'Ghi chú mới (Chưa lưu)';
    }
  });

  btnSaveNoteGithub.addEventListener('click', async () => {
    if (!config.token) {
      showToast('Cần có GitHub Token để lưu ghi chú.', 'error');
      modalSettings.style.display = 'flex';
      return;
    }

    const title = noteTitleInput.value.trim();
    if (!title) {
      showToast('Vui lòng nhập tên tiêu đề ghi chú.', 'error');
      return;
    }

    const filePath = currentNoteFile && currentNoteFile.path ? currentNoteFile.path : `notes/${title}`;
    const content = noteMarkdownTextarea.value;

    try {
      showToast('Đang lưu ghi chú vào GitHub...', 'info');
      const res = await api.uploadFile(
        config.owner,
        config.repo,
        filePath,
        storage.utf8ToBase64(content),
        `EduVault: Lưu ghi chú ${title}`,
        currentNoteFile ? currentNoteFile.sha : null,
        config.branch,
        config.token
      );
      if (currentNoteFile) currentNoteFile.sha = res.content.sha;
      noteSaveStatus.textContent = 'Đã lưu lên GitHub';
      showToast(`Đã lưu ghi chú '${title}' thành công!`, 'success');
      loadNotesList();
    } catch (e) {
      showToast(`Lỗi lưu ghi chú: ${e.message}`, 'error');
    }
  });

  // Note View Mode Buttons
  btnNoteSplit.addEventListener('click', () => {
    btnNoteSplit.classList.add('active');
    btnNoteEditOnly.classList.remove('active');
    btnNotePreviewOnly.classList.remove('active');
    notePanelsContainer.className = 'note-panels-container split-view';
  });

  btnNoteEditOnly.addEventListener('click', () => {
    btnNoteEditOnly.classList.add('active');
    btnNoteSplit.classList.remove('active');
    btnNotePreviewOnly.classList.remove('active');
    notePanelsContainer.className = 'note-panels-container edit-only';
  });

  btnNotePreviewOnly.addEventListener('click', () => {
    btnNotePreviewOnly.classList.add('active');
    btnNoteSplit.classList.remove('active');
    btnNoteEditOnly.classList.remove('active');
    notePanelsContainer.className = 'note-panels-container preview-only';
  });

  // ==========================================================================
  // TAB 3: Exam Bank (Ngân Hàng Đề Thi)
  // ==========================================================================
  async function loadExamsData() {
    examsTableBody.innerHTML = '<tr><td colspan="7" style="text-align:center; padding:2rem;"><i class="fa-solid fa-spinner fa-spin"></i> Đang tải ngân hàng đề thi...</td></tr>';
    emptyExamState.style.display = 'none';

    try {
      const fileData = await api.getFileDetails(config.owner, config.repo, storage.EXAM_DATA_PATH, config.branch, config.token);
      examFileSha = fileData.sha;
      const str = storage.base64ToUtf8(fileData.content || '[]');
      examRecords = storage.safeJsonParse(str, []);
      renderExamsTable(examRecords);
    } catch (e) {
      examRecords = [];
      examFileSha = null;
      renderExamsTable([]);
    }
  }

  function renderExamsTable(records) {
    examsTableBody.innerHTML = '';
    examStatusSummary.innerHTML = `<span class="count-badge total">${records.length} Đề thi</span>`;

    if (!records || records.length === 0) {
      emptyExamState.style.display = 'block';
      return;
    }

    emptyExamState.style.display = 'none';

    records.forEach((rec, idx) => {
      const tr = document.createElement('tr');
      let diffClass = 'diff-easy';
      if (rec.difficulty === 'Trung bình') diffClass = 'diff-med';
      if (rec.difficulty === 'Khó') diffClass = 'diff-hard';

      let statusClass = 'status-todo';
      if (rec.status === 'Đã hoàn thành') statusClass = 'status-done';
      if (rec.status === 'Cần ôn lại') statusClass = 'status-review';

      tr.innerHTML = `
        <td><strong>${rec.title || 'Chưa đặt tên'}</strong></td>
        <td><span class="tag-badge" style="background:#1e293b; color:var(--mint);">${rec.subject || 'Đại cương'}</span></td>
        <td>${rec.term || 'HK1'}</td>
        <td><span class="tag-badge ${diffClass}">${rec.difficulty || 'Trung bình'}</span></td>
        <td><span class="${statusClass}">${rec.status || 'Chưa làm'}</span></td>
        <td>${rec.link ? `<a href="${rec.link}" target="_blank" class="text-link"><i class="fa-solid fa-arrow-up-right-from-square"></i> Mở đề thi</a>` : '—'}</td>
        <td>
          <div style="display:flex; gap:0.4rem;">
            <button class="btn-subtle-sm btn-edit-exam" data-id="${rec.id}"><i class="fa-regular fa-pen-to-square"></i></button>
            <button class="btn-danger-sm btn-del-exam" data-id="${rec.id}"><i class="fa-regular fa-trash-can"></i></button>
          </div>
        </td>
      `;

      tr.querySelector('.btn-edit-exam').addEventListener('click', () => openExamModal(rec));
      tr.querySelector('.btn-del-exam').addEventListener('click', () => deleteExam(rec.id));

      examsTableBody.appendChild(tr);
    });
  }

  // Filter exam table
  examSearchInput.addEventListener('input', (e) => {
    const q = e.target.value.toLowerCase().trim();
    if (!q) return renderExamsTable(examRecords);
    const filtered = examRecords.filter(r => 
      (r.title && r.title.toLowerCase().includes(q)) ||
      (r.subject && r.subject.toLowerCase().includes(q))
    );
    renderExamsTable(filtered);
  });

  function openExamModal(record = null) {
    if (record) {
      examEditId.value = record.id;
      examInTitle.value = record.title || '';
      examInSubject.value = record.subject || '';
      examInTerm.value = record.term || '';
      examInDifficulty.value = record.difficulty || 'Trung bình';
      examInStatus.value = record.status || 'Chưa làm';
      examInLink.value = record.link || '';
    } else {
      examEditId.value = '';
      examInTitle.value = '';
      examInSubject.value = '';
      examInTerm.value = '';
      examInDifficulty.value = 'Trung bình';
      examInStatus.value = 'Chưa làm';
      examInLink.value = '';
    }
    modalExam.style.display = 'flex';
    examInTitle.focus();
  }

  btnOpenAddExamModal.addEventListener('click', () => {
    if (!config.token) {
      showToast('Cần có GitHub Token để thêm đề thi.', 'error');
      modalSettings.style.display = 'flex';
      return;
    }
    openExamModal(null);
  });

  btnCloseExam.addEventListener('click', () => modalExam.style.display = 'none');
  btnCancelExam.addEventListener('click', () => modalExam.style.display = 'none');

  btnSaveExam.addEventListener('click', async () => {
    const title = examInTitle.value.trim();
    const subject = examInSubject.value.trim();
    if (!title || !subject) {
      showToast('Vui lòng nhập tên đề thi và môn học.', 'error');
      return;
    }

    const editId = examEditId.value;
    let updated = [...examRecords];

    if (editId) {
      updated = updated.map(r => r.id === editId ? {
        ...r,
        title,
        subject,
        term: examInTerm.value.trim(),
        difficulty: examInDifficulty.value,
        status: examInStatus.value,
        link: examInLink.value.trim()
      } : r);
    } else {
      updated.unshift({
        id: 'exam_' + Date.now().toString(36),
        title,
        subject,
        term: examInTerm.value.trim(),
        difficulty: examInDifficulty.value,
        status: examInStatus.value,
        link: examInLink.value.trim(),
        createdAt: new Date().toISOString()
      });
    }

    try {
      modalExam.style.display = 'none';
      showToast('Đang lưu đề thi vào GitHub...', 'info');
      const jsonStr = JSON.stringify(updated, null, 2);
      const res = await api.uploadFile(
        config.owner,
        config.repo,
        storage.EXAM_DATA_PATH,
        storage.utf8ToBase64(jsonStr),
        `EduVault: Cập nhật ngân hàng đề thi`,
        examFileSha,
        config.branch,
        config.token
      );
      examFileSha = res.content.sha;
      examRecords = updated;
      renderExamsTable(examRecords);
      showToast('Đã lưu đề thi thành công!', 'success');
    } catch (e) {
      showToast(`Lỗi lưu đề thi: ${e.message}`, 'error');
    }
  });

  async function deleteExam(id) {
    if (!config.token) {
      showToast('Cần có GitHub Token để xóa.', 'error');
      return;
    }
    if (!confirm('Bạn có chắc chắn muốn xóa đề thi này?')) return;

    const updated = examRecords.filter(r => r.id !== id);
    try {
      showToast('Đang xóa đề thi...', 'info');
      const res = await api.uploadFile(
        config.owner,
        config.repo,
        storage.EXAM_DATA_PATH,
        storage.utf8ToBase64(JSON.stringify(updated, null, 2)),
        `EduVault: Xóa đề thi ${id}`,
        examFileSha,
        config.branch,
        config.token
      );
      examFileSha = res.content.sha;
      examRecords = updated;
      renderExamsTable(examRecords);
      showToast('Đã xóa đề thi!', 'success');
    } catch (e) {
      showToast(`Lỗi: ${e.message}`, 'error');
    }
  }

  // Export Exam Data
  btnExportExamData.addEventListener('click', () => {
    const blob = new Blob([JSON.stringify(examRecords, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `eduvault_de_thi_${Date.now()}.json`;
    a.click();
    URL.revokeObjectURL(url);
    showToast('Đã xuất file dữ liệu đề thi!', 'success');
  });

  // ==========================================================================
  // File Viewer Modal
  // ==========================================================================
  async function openViewerModal(item) {
    viewerFileName.textContent = item.name;
    const info = storage.classifyStudyFile(item.name);
    viewerFileIcon.className = `${info.icon} ${info.cssClass}`;

    const cdnUrls = api.getPublicUrls(config.owner, config.repo, item.path, config.branch);
    btnViewerDownload.href = item.download_url || cdnUrls.raw;
    btnViewerDownload.setAttribute('download', item.name);

    btnViewerCopyCdn.onclick = () => {
      navigator.clipboard.writeText(cdnUrls.jsdelivr);
      showToast('Đã sao chép link CDN jsDelivr!', 'success');
    };

    btnViewerDelete.onclick = async () => {
      if (!config.token) return showToast('Cần có Token để xóa tài liệu.', 'error');
      if (confirm(`Bạn có chắc muốn xóa '${item.name}' khỏi kho dữ liệu?`)) {
        try {
          showToast('Đang xóa tài liệu...', 'info');
          await api.deleteFile(config.owner, config.repo, item.path, item.sha, `EduVault: Xóa ${item.name}`, config.branch, config.token);
          modalViewer.style.display = 'none';
          showToast(`Đã xóa ${item.name}!`, 'success');
          loadDirectory(currentPath);
        } catch (e) {
          showToast(`Lỗi: ${e.message}`, 'error');
        }
      }
    };

    viewerBodyContent.innerHTML = '<div style="text-align:center; padding:3rem;"><i class="fa-solid fa-spinner fa-spin text-mint"></i> Đang tải nội dung...</div>';
    viewerFoot.style.display = 'none';
    modalViewer.style.display = 'flex';

    try {
      const fileData = await api.getFileDetails(config.owner, config.repo, item.path, config.branch, config.token);
      
      if (item.name.toLowerCase().endsWith('.pdf')) {
        viewerBodyContent.innerHTML = `
          <iframe src="https://docs.google.com/viewer?url=${encodeURIComponent(cdnUrls.raw)}&embedded=true" style="width:100%; height:100%; min-height:560px; border:none; border-radius:8px;"></iframe>
        `;
      } else if (info.category === 'image') {
        viewerBodyContent.innerHTML = `
          <div style="display:flex; justify-content:center; align-items:center; height:100%;">
            <img src="${cdnUrls.jsdelivr}" alt="${item.name}" style="max-width:100%; max-height:65vh; border-radius:8px; object-fit:contain;">
          </div>
        `;
      } else if (info.category === 'video') {
        viewerBodyContent.innerHTML = `
          <div style="display:flex; justify-content:center; align-items:center; height:100%;">
            <video controls autoplay style="max-width:100%; max-height:60vh; border-radius:8px;">
              <source src="${cdnUrls.raw}">
            </video>
          </div>
        `;
      } else if (['code', 'notes', 'other'].includes(info.category)) {
        const decoded = storage.base64ToUtf8(fileData.content || '');
        currentEditingFile = { name: item.name, path: item.path, sha: fileData.sha };
        viewerBodyContent.innerHTML = `
          <textarea id="viewer-code-editor" class="markdown-textarea" style="height:500px;" spellcheck="false">${decoded}</textarea>
        `;
        viewerFoot.style.display = 'flex';
      } else {
        viewerBodyContent.innerHTML = `
          <div class="study-empty">
            <div class="empty-icon-box"><i class="${info.icon}"></i></div>
            <h3>Tệp định dạng ${item.name.split('.').pop().toUpperCase()}</h3>
            <p>Định dạng này phù hợp tải xuống trực tiếp hoặc mở bằng ứng dụng trên máy.</p>
          </div>
        `;
      }
    } catch (err) {
      viewerBodyContent.innerHTML = `<div class="study-empty"><p class="text-danger">Lỗi: ${err.message}</p></div>`;
    }
  }

  btnCloseViewer.addEventListener('click', () => {
    modalViewer.style.display = 'none';
    currentEditingFile = null;
  });

  btnViewerSaveChanges.addEventListener('click', async () => {
    if (!config.token || !currentEditingFile) return showToast('Cần có Token để lưu thay đổi.', 'error');
    const editor = document.getElementById('viewer-code-editor');
    const newContent = editor ? editor.value : '';

    try {
      showToast('Đang commit thay đổi lên GitHub...', 'info');
      const res = await api.uploadFile(
        config.owner,
        config.repo,
        currentEditingFile.path,
        storage.utf8ToBase64(newContent),
        `EduVault: Cập nhật ${currentEditingFile.name}`,
        currentEditingFile.sha,
        config.branch,
        config.token
      );
      currentEditingFile.sha = res.content.sha;
      showToast(`Đã lưu thay đổi vào ${currentEditingFile.name}!`, 'success');
      loadDirectory(currentPath);
    } catch (e) {
      showToast(`Lỗi: ${e.message}`, 'error');
    }
  });

  // ==========================================================================
  // Settings & Configuration Modal
  // ==========================================================================
  function openSettings() {
    cfgOwner.value = config.owner;
    cfgRepo.value = config.repo;
    cfgBranch.value = config.branch || 'main';
    cfgToken.value = config.token || '';
    cfgFeedback.style.display = 'none';
    modalSettings.style.display = 'flex';
  }

  btnOpenSettings.addEventListener('click', openSettings);
  btnCloseSettings.addEventListener('click', () => modalSettings.style.display = 'none');

  btnToggleCfgToken.addEventListener('click', () => {
    const isPw = cfgToken.type === 'password';
    cfgToken.type = isPw ? 'text' : 'password';
    btnToggleCfgToken.innerHTML = isPw ? '<i class="fa-regular fa-eye-slash"></i>' : '<i class="fa-regular fa-eye"></i>';
  });

  btnTestCfg.addEventListener('click', async () => {
    const o = cfgOwner.value.trim();
    const r = cfgRepo.value.trim();
    const t = cfgToken.value.trim();

    if (!o || !r) {
      cfgFeedback.className = 'feedback-box error';
      cfgFeedback.style.display = 'block';
      cfgFeedback.textContent = 'Vui lòng nhập Username và Tên Kho lưu trữ.';
      return;
    }

    cfgFeedback.className = 'feedback-box';
    cfgFeedback.style.display = 'block';
    cfgFeedback.textContent = 'Đang kiểm tra kết nối tới GitHub...';

    try {
      const details = await api.getRepoDetails(o, r, t);
      cfgFeedback.className = 'feedback-box success';
      cfgFeedback.innerHTML = `Kết nối thành công tới kho <strong>${details.full_name}</strong>! ${t ? '(Đã có quyền ghi Token)' : '(Chế độ xem công khai)'}`;
    } catch (e) {
      cfgFeedback.className = 'feedback-box error';
      cfgFeedback.textContent = `Lỗi: ${e.message}`;
    }
  });

  btnSaveCfg.addEventListener('click', () => {
    const owner = cfgOwner.value.trim();
    const repo = cfgRepo.value.trim();
    const branch = cfgBranch.value.trim() || 'main';
    const token = cfgToken.value.trim();

    if (!owner || !repo) return showToast('Vui lòng điền đủ thông tin kho.', 'error');

    config = { owner, repo, branch, token };
    storage.saveConfig(config);
    modalSettings.style.display = 'none';

    headerRepoText.textContent = `${config.owner}/${config.repo}`;
    loadDirectory('');
    showToast('Đã lưu cấu hình và kết nối thành công!', 'success');
  });

  btnRefresh.addEventListener('click', () => {
    loadDirectory(currentPath);
    showToast('Đã làm mới dữ liệu!', 'info');
  });

  // Initial Load
  headerRepoText.textContent = `${config.owner}/${config.repo}`;
  loadDirectory('');
});
