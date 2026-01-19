module app;

import std.stdio;
import std.file;
import std.path;
import std.algorithm;
import std.array;
import std.conv;
import std.exception;

import image_io : isImageFile;
import ocr : runTesseract;
import classify : titleToFolder;

void main(string[] args)
{
    if (args.length < 3)
    {
        writeln("Usage: dub run -- <input_dir> <output_dir>");
        return;
    }

    string inputDir = args[1];
    string outputDir = args[2];

    enforce(exists(inputDir) && isDir(inputDir), "输入目录不存在或不是目录: " ~ inputDir);
    ensureDirExists(outputDir);

    string cleanedDir = buildPath(outputDir, "cleaned");
    string categorizedDir = buildPath(outputDir, "categorized");
    string unknownDir = buildPath(outputDir, "unknown");

    ensureDirExists(cleanedDir);
    ensureDirExists(categorizedDir);
    ensureDirExists(unknownDir);

    auto entries = dirEntries(inputDir, SpanMode.shallow).map!(e => e.name).array;
    foreach (entry; entries)
    {
        string full = buildPath(inputDir, entry);
        if (!isFile(full) || !isImageFile(entry)) continue;

        writeln("Processing: ", entry);

        // 1) Call Python inpaint script to remove handwriting
        string cleanedOut = buildPath(cleanedDir, entry);
        auto inpaintCmd = ["python3", "scripts/inpaint.py", full, cleanedOut];
        auto res = execute(inpaintCmd);
        if (res.status != 0)
        {
            writeln("  [ERROR] inpaint failed for ", entry, " -> ", res.stderr);
            // Move file to unknown and continue
            std.file.move(full, buildPath(unknownDir, entry));
            continue;
        }

        // 2) Run OCR on cleaned image
        string ocrText = runTesseract(cleanedOut);
        auto firstLine = extractFirstNonEmptyLine(ocrText);
        writeln("  OCR first line: '", firstLine, "'");

        // 3) Decide folder by title
        string targetFolder;
        if (firstLine.length == 0)
        {
            targetFolder = unknownDir;
        }
        else
        {
            string folderName = titleToFolder(firstLine);
            targetFolder = buildPath(categorizedDir, folderName);
            ensureDirExists(targetFolder);
        }

        // 4) Move original and cleaned copy into category folder
        string destOriginal = buildPath(targetFolder, entry);
        string destCleaned = buildPath(targetFolder, "cleaned_" ~ entry);
        try
        {
            // move original
            if (exists(full))
                std.file.move(full, destOriginal, Overwrite.no);
            // copy cleaned
            std.file.copy(cleanedOut, destCleaned, Overwrite.yes);
            writeln("  Saved to: ", targetFolder);
        }
        catch (Exception e)
        {
            writeln("  [ERROR] moving files: ", e.msg);
        }
    }

    writeln("Done.");
}

string extractFirstNonEmptyLine(string s)
{
    foreach (line; s.splitLines())
    {
        auto t = line.strip();
        if (t.length > 0) return t;
    }
    return "";
}

void ensureDirExists(string p)
{
    if (!exists(p)) mkdirRecurse(p);
}