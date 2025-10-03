const multer = require('multer');
const sharp = require('sharp');
const path = require('path');
const fs = require('fs').promises;

class ImageUploadMiddleware {
    
    // Configure multer for in-memory storage (we'll process with sharp)
    static getMulterConfig() {
        const storage = multer.memoryStorage();

        const fileFilter = (req, file, cb) => {
            console.log(`📁 Filtering file: ${file.originalname} (${file.mimetype})`);

            // Check if the file is an image
            if (file.mimetype.startsWith('image/')) {
                // Allowed image types
                const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
                
                if (allowedTypes.includes(file.mimetype)) {
                    console.log(`✅ File accepted: ${file.originalname}`);
                    cb(null, true);
                } else {
                    console.log(`❌ File rejected - unsupported type: ${file.mimetype}`);
                    cb(new Error(`Unsupported image format: ${file.mimetype}. Supported formats: JPEG, PNG, GIF, WebP`), false);
                }
            } else {
                console.log(`❌ File rejected - not an image: ${file.mimetype}`);
                cb(new Error('Only image files are allowed'), false);
            }
        };

        const limits = {
            fileSize: 10 * 1024 * 1024, // 10MB per file
            files: 10 // Maximum 10 files per request
        };

        return multer({
            storage,
            fileFilter,
            limits
        });
    }

    // Middleware for uploading multiple images with Sharp processing
    static uploadImages() {
        const upload = this.getMulterConfig();
        
        return async (req, res, next) => {
            console.log('\n=== 📁 IMAGE UPLOAD MIDDLEWARE CALLED ===');
            
            upload.array('images', 10)(req, res, async (err) => {
                if (err) {
                    console.error('❌ Upload error:', err.message);
                    
                    if (err instanceof multer.MulterError) {
                        if (err.code === 'LIMIT_FILE_SIZE') {
                            return res.status(400).json({
                                success: false,
                                message: 'File too large. Maximum size is 10MB per image.'
                            });
                        } else if (err.code === 'LIMIT_FILE_COUNT') {
                            return res.status(400).json({
                                success: false,
                                message: 'Too many files. Maximum 10 images per message.'
                            });
                        } else if (err.code === 'LIMIT_UNEXPECTED_FILE') {
                            return res.status(400).json({
                                success: false,
                                message: 'Unexpected field name. Use "images" for file uploads.'
                            });
                        }
                    }

                    return res.status(400).json({
                        success: false,
                        message: err.message || 'File upload error'
                    });
                }

                // Check if files were uploaded
                if (!req.files || req.files.length === 0) {
                    console.log('❌ No files received in upload');
                    return res.status(400).json({
                        success: false,
                        message: 'No images uploaded'
                    });
                }

                console.log(`✅ Successfully received ${req.files.length} files:`);
                req.files.forEach((file, index) => {
                    console.log(`   ${index + 1}. ${file.originalname} (${(file.size / 1024).toFixed(2)} KB, ${file.mimetype})`);
                });

                // Process images with Sharp
                try {
                    console.log('🖼️ Processing images with Sharp...');
                    req.processedImages = await Promise.all(
                        req.files.map(async (file, index) => {
                            return await ImageUploadMiddleware.processImage(file, index);
                        })
                    );

                    console.log('✅ All images processed successfully');
                    console.log('📊 Processed images count:', req.processedImages.length);
                    next();
                } catch (processError) {
                    console.log('❌ Image processing error:', processError.message);
                    return res.status(500).json({
                        success: false,
                        message: 'Error processing images: ' + processError.message
                    });
                }
            });
        };
    }

    // Process individual image with compression
    static async processImage(file, index) {
        try {
            const timestamp = Date.now();
            const originalName = file.originalname;
            const fileName = `img_${timestamp}_${index}_${Math.random().toString(36).substring(7)}`;
            const ext = path.extname(originalName) || '.jpg';
            
            // Use existing upload directories
            const originalDir = path.join(process.cwd(), 'uploads', 'images', 'complaints');
            const compressedDir = path.join(process.cwd(), 'uploads', 'images', 'compressed');
            
            // Ensure directories exist
            try {
                await fs.mkdir(originalDir, { recursive: true });
                await fs.mkdir(compressedDir, { recursive: true });
            } catch (dirError) {
                console.log('⚠️ Directory creation warning:', dirError.message);
            }
            
            // File paths
            const originalPath = path.join(originalDir, fileName + ext);
            const compressedPath = path.join(compressedDir, fileName + ext);
            
            console.log(`📁 Processing image ${index + 1}: ${originalName}`);
            console.log(`💾 Original size: ${(file.size / 1024).toFixed(2)} KB`);
            console.log(`📂 Saving to: ${path.basename(originalPath)}`);
            
            // Save original image
            await fs.writeFile(originalPath, file.buffer);
            
            // Get image metadata
            const metadata = await sharp(file.buffer).metadata();
            console.log(`📐 Original dimensions: ${metadata.width}x${metadata.height}`);
            
            // Compress image
            const compressedBuffer = await sharp(file.buffer)
                .resize(1200, 1200, { 
                    fit: 'inside',
                    withoutEnlargement: true 
                })
                .jpeg({ 
                    quality: 80,
                    progressive: true 
                })
                .toBuffer();
            
            // Save compressed image
            await fs.writeFile(compressedPath, compressedBuffer);
            
            const compressedSize = compressedBuffer.length;
            const compressionRatio = ((file.size - compressedSize) / file.size * 100).toFixed(2);
            
            console.log(`✅ Compressed to: ${(compressedSize / 1024).toFixed(2)} KB (${compressionRatio}% reduction)`);
            
            return {
                originalName: originalName,
                fileName: fileName + ext,
                originalPath: originalPath,
                compressedPath: compressedPath,
                originalSize: file.size,
                compressedSize: compressedSize,
                compressionRatio: parseFloat(compressionRatio),
                dimensions: {
                    width: metadata.width,
                    height: metadata.height
                },
                mimetype: file.mimetype
            };
        } catch (error) {
            console.log('❌ Error processing image:', error.message);
            throw new Error(`Failed to process image: ${error.message}`);
        }
    }

    // Middleware for uploading single image
    static uploadSingleImage() {
        const upload = this.getMulterConfig();
        
        return (req, res, next) => {
            console.log('\n=== 📁 SINGLE IMAGE UPLOAD MIDDLEWARE CALLED ===');
            
            upload.single('image')(req, res, (err) => {
                if (err) {
                    console.error('❌ Upload error:', err.message);
                    
                    if (err instanceof multer.MulterError) {
                        if (err.code === 'LIMIT_FILE_SIZE') {
                            return res.status(400).json({
                                success: false,
                                message: 'File too large. Maximum size is 10MB.'
                            });
                        }
                    }

                    return res.status(400).json({
                        success: false,
                        message: err.message || 'File upload error'
                    });
                }

                // Log successful upload
                if (req.file) {
                    console.log(`✅ Successfully received file: ${req.file.originalname} (${(req.file.size / 1024).toFixed(2)} KB, ${req.file.mimetype})`);
                } else {
                    console.log('ℹ️ No file received in upload');
                }

                next();
            });
        };
    }
}

module.exports = ImageUploadMiddleware;