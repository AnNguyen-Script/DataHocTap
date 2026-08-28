/**
 * EduVault - Storage & Academic State Manager
 * Pre-configured for AnNguyen-Script/DataHocTap repository.
 * Handles Study categories, Base64 UTF-8 encoding, and local persistence.
 */

class StorageManager {
  constructor() {
    this.CONFIG_KEY = 'eduvault_study_config';
    this.EXAM_DATA_PATH = 'data/exams.json';
    this.NOTES_FOLDER = 'notes';
  }

  /**
   * Get configuration with user's repository as default
   */
  getConfig() {
    const defaultStudyConfig = {
      owner: 'AnNguyen-Script',
      repo: 'DataHocTap',
      branch: 'main',
      token: ''
    };

    try {
      const stored = localStorage.getItem(this.CONFIG_KEY);
      if (stored) {
        return { ...defaultStudyConfig, ...JSON.parse(stored) };
      }
    } catch (e) {
      console.warn('Không thể đọc cấu hình EduVault:', e);
    }
    return defaultStudyConfig;
  }

  /**
   * Save configuration
   */
  saveConfig(config) {
    try {
      localStorage.setItem(this.CONFIG_KEY, JSON.stringify(config));
    } catch (e) {
      console.error('Không thể lưu cấu hình:', e);
    }
  }

  /**
   * Format file size
   */
  formatBytes(bytes, decimals = 1) {
    if (!+bytes) return '0 B';
    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return `${parseFloat((bytes / Math.pow(k, i)).toFixed(dm))} ${sizes[i]}`;
  }

  /**
   * Classify study files into academic categories
   */
  classifyStudyFile(filename) {
    const ext = filename.split('.').pop().toLowerCase();

    // Slides & Presentations
    if (['ppt', 'pptx', 'key', 'odp'].includes(ext)) {
      return {
        category: 'slide',
        label: 'Slide Bài Giảng',
        icon: 'fa-solid fa-person-chalkboard',
        cssClass: 'type-slide',
        isPreviewable: false
      };
    }

    // Textbooks, PDFs & Docs
    if (['pdf', 'epub', 'doc', 'docx', 'djvu', 'odt'].includes(ext)) {
      return {
        category: 'document',
        label: 'Giáo Trình / PDF',
        icon: 'fa-regular fa-file-pdf',
        cssClass: 'type-pdf',
        isPreviewable: ext === 'pdf'
      };
    }

    // Code & Programming Homework
    if (['cpp', 'c', 'h', 'hpp', 'py', 'java', 'js', 'ts', 'html', 'css', 'sql', 'sh', 'json', 'zip', 'rar', '7z'].includes(ext)) {
      return {
        category: 'code',
        label: 'Code / Bài Tập',
        icon: 'fa-solid fa-code',
        cssClass: 'type-code',
        isPreviewable: !['zip', 'rar', '7z'].includes(ext)
      };
    }

    // Markdown Notes
    if (['md', 'markdown', 'txt'].includes(ext)) {
      return {
        category: 'notes',
        label: 'Ghi Chú',
        icon: 'fa-regular fa-file-lines',
        cssClass: 'type-notes',
        isPreviewable: true
      };
    }

    // Mindmaps & Diagram Images
    if (['png', 'jpg', 'jpeg', 'svg', 'webp', 'gif', 'bmp'].includes(ext)) {
      return {
        category: 'image',
        label: 'Mindmap / Ảnh',
        icon: 'fa-regular fa-image',
        cssClass: 'type-image',
        isPreviewable: true
      };
    }

    // Lecture Audio & Video
    if (['mp4', 'webm', 'mp3', 'wav', 'm4a', 'ogg', 'mov'].includes(ext)) {
      return {
        category: 'video',
        label: 'Video / Audio Học',
        icon: 'fa-regular fa-file-video',
        cssClass: 'type-slide',
        isPreviewable: true
      };
    }

    return {
      category: 'other',
      label: 'Tài Liệu Khác',
      icon: 'fa-regular fa-file',
      cssClass: 'type-code',
      isPreviewable: false
    };
  }

  /**
   * Convert File to Base64
   */
  fileToBase64(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.readAsDataURL(file);
      reader.onload = () => {
        const base64 = reader.result.split(',')[1];
        resolve(base64);
      };
      reader.onerror = error => reject(error);
    });
  }

  /**
   * UTF-8 String to Base64 (Full Unicode support for Vietnamese)
   */
  utf8ToBase64(str) {
    const bytes = new TextEncoder().encode(str);
    const binString = Array.from(bytes, (byte) => String.fromCharCode(byte)).join('');
    return btoa(binString);
  }

  /**
   * Base64 to UTF-8 String
   */
  base64ToUtf8(base64) {
    try {
      const cleanBase64 = base64.replace(/\s/g, '');
      const binString = atob(cleanBase64);
      const bytes = Uint8Array.from(binString, (m) => m.charCodeAt(0));
      return new TextDecoder().decode(bytes);
    } catch (e) {
      console.warn('UTF-8 decode fallback:', e);
      return atob(base64);
    }
  }

  safeJsonParse(str, fallback = []) {
    try {
      return JSON.parse(str);
    } catch (e) {
      return fallback;
    }
  }
}

// Attach globally
window.StorageManager = StorageManager;
