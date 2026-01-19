module image_io;

// 辅助：判断文件名是否是图片（简单后缀判断）
import std.string : toLower;
import std.algorithm : endsWith;

bool isImageFile(string filename)
{
    auto lower = filename.toLower();
    return lower.endsWith(".jpg") || lower.endsWith(".jpeg") || lower.endsWith(".png") || lower.endsWith(".tif") || lower.endsWith(".tiff");
}
