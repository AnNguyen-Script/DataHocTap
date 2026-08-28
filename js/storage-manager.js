/**
 * GitVault - Storage & State Manager
 * Handles local preferences, Base64 transformations, File Metadata Helpers, and JSON Database Engine.
 */

class StorageManager {
  constructor() {
    this.CONFIG_KEY = 'gitvault_config';
    this.CACHE_KEY = 'gitvault_cached_data';
  }

  /**
   * Load saved configuration from LocalStorage
   */
  getConfig() {
    const defaultPublicConfig = {
      owner: 'facebook',
      repo: 'react',
      branch: 'main',
      token: ''
    };

    try {
      const stored = localStorage.getItem(this.CONFIG_KEY);
      if (stored) {
        return { ...defaultPublicConfig, ...JSON.parse(stored) };
      }
    } catch (e) {
      console.warn('Không thể đọc cấu hình từ localStorage:', e);
    }
    return defaultPublicConfig;
  }

  /**
   * Save configuration to LocalStorage
   */
  saveConfig(config) {
    try {
      localStorage.setItem(this.CONFIG_KEY, JSON.stringify(config));
    } catch (e) {
      console.error('Không thể lưu cấu hình:', e);
    }
  }

  /**
   * Format bytes into human-readable string (KB, MB, GB)
   */
  formatBytes(bytes, decimals = 2) {
    if (!+bytes) return '0 B';
    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return `${parseFloat((bytes / Math.pow(k, i)).toFixed(dm))} ${sizes[i]}`;
  }

  /**
   * Resolve file icon & file type category based on extension
   */
  getFileTypeInfo(filename) {
    const ext = filename.split('.').pop().toLowerCase();
    
    // Image formats
    if (['jpg', 'jpeg', 'png', 'gif', 'svg', 'webp', 'ico', 'avif', 'bmp'].includes(ext)) {
      return { type: 'image', icon: 'fa-regular fa-image', color: 'text-cyan', isPreviewable: true };
    }
    // Code & Markup
    if (['js', 'ts', 'jsx', 'tsx', 'html', 'css', 'scss', 'json', 'py', 'php', 'java', 'c', 'cpp', 'rs', 'go', 'sql', 'sh', 'yaml', 'yml'].includes(ext)) {
      return { type: 'code', icon: 'fa-solid fa-code', color: 'text-indigo', isPreviewable: true };
    }
    // Markdown & Text
    if (['md', 'markdown', 'txt', 'rtf', 'log', 'env'].includes(ext)) {
      return { type: 'text', icon: 'fa-regular fa-file-lines', color: 'text-purple', isPreviewable: true };
    }
    // Documents
    if (['pdf'].includes(ext)) {
      return { type: 'pdf', icon: 'fa-regular fa-file-pdf', color: 'text-danger', isPreviewable: true };
    }
    // Video
    if (['mp4', 'webm', 'ogg', 'mov'].includes(ext)) {
      return { type: 'video', icon: 'fa-regular fa-file-video', color: 'text-purple', isPreviewable: true };
    }
    // Audio
    if (['mp3', 'wav', 'ogg', 'aac', 'flac'].includes(ext)) {
      return { type: 'audio', icon: 'fa-regular fa-file-audio', color: 'text-cyan', isPreviewable: true };
    }
    // Archives
    if (['zip', 'rar', '7z', 'tar', 'gz'].includes(ext)) {
      return { type: 'archive', icon: 'fa-regular fa-file-zipper', color: 'text-warning', isPreviewable: false };
    }

    // Default generic file
    return { type: 'generic', icon: 'fa-regular fa-file', color: 'text-muted', isPreviewable: false };
  }

  /**
   * Convert File object to Base64 String (for GitHub API upload)
   */
  fileToBase64(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.readAsDataURL(file);
      reader.onload = () => {
        // Strip the data URL prefix (e.g., "data:image/png;base64,")
        const base64 = reader.result.split(',')[1];
        resolve(base64);
      };
      reader.onerror = error => reject(error);
    });
  }

  /**
   * Convert UTF-8 string to Base64 (supporting Unicode characters)
   */
  utf8ToBase64(str) {
    const bytes = new TextEncoder().encode(str);
    const binString = Array.from(bytes, (byte) => String.fromCharCode(byte)).join('');
    return btoa(binString);
  }

  /**
   * Decode Base64 string to UTF-8 (supporting Unicode characters)
   */
  base64ToUtf8(base64) {
    try {
      const cleanBase64 = base64.replace(/\s/g, '');
      const binString = atob(cleanBase64);
      const bytes = Uint8Array.from(binString, (m) => m.charCodeAt(0));
      return new TextDecoder().decode(bytes);
    } catch (e) {
      console.warn('UTF-8 decode failed, falling back to atob:', e);
      return atob(base64);
    }
  }

  /**
   * Safe JSON parse with fallback
   */
  safeJsonParse(jsonString, fallback = []) {
    try {
      return JSON.parse(jsonString);
    } catch (e) {
      console.warn('Lỗi parse JSON:', e);
      return fallback;
    }
  }
}

// Attach globally
window.StorageManager = StorageManager;
