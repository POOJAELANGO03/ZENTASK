// lib/core/services/cloudinary_constants.dart (UPDATED with Credentials)

// 🔑 Your Cloudinary Account Details
class CloudinaryConstants {
  static const String CLOUD_NAME = 'dgd5y6149'; // Extracted from CLOUDINARY_URL
  
  // These are for reference/server-side, but good practice to define.
  static const String API_KEY = '829882985184266';
  static const String API_SECRET = 'bT9UfCWb-HcIFX9Gxsy3oj9Xzjo';
  
  // NOTE: REPLACE THIS WITH THE ACTUAL UPLOAD PRESET NAME YOU CREATED (e.g., 'coursehive_videos')
  static const String UPLOAD_PRESET = 'zentask'; 
  
  // The upload endpoint URL (uses 'video' resource type)
  static const String UPLOAD_URL = 'https://api.cloudinary.com/v1_1/dgd5y6149/video/upload';
}