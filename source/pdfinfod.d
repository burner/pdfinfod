module pdfinfod;

import std.array;
import std.algorithm.iteration : filter, map, splitter;
import std.datetime.systime;
import std.typecons;
import std.conv : to;
import std.exception : enforce;
import std.process : execute;
import std.file : exists;
import std.string;

@safe:

///
struct PdfInfo {
	string title;           
	string author;          
	string producer;        
	string creator;        
	SysTime creationDate;    
	SysTime modDate;         
	bool custom_metadata; 
	bool metadata_stream; 
	bool tagged;          
	bool userProperties;  
	bool suspects;        
	string form;            
	bool javaScript;      
	long pages;           
	bool encrypted;       
	string page_size;       
	double page_rot;        
	long sizeInBytes;
	bool linearized;        
	bool optimized;       
	string pdf_version;     
}

///
PdfInfo extractPdfInfo(string pdfFilename) {
	import std.file : getSize;

	enforce(exists(pdfFilename), "'" ~ pdfFilename ~ "' does not exist");

	auto pdfinfo = execute(["pdfinfo", "-isodates", pdfFilename]);

	PdfInfo ret = parsePdfInfo(pdfinfo.output);
	ret.sizeInBytes = getSize(pdfFilename);
	return ret;
}

unittest {
	import std.math : isClose;
	auto parsed = extractPdfInfo("test.pdf");
	assert(parsed.title == "Dlang pdfinfo test file");
	assert(parsed.author == "Yours truly");
	assert(parsed.producer == "pdflatex with hyperref on archlinux");
	assert(parsed.creator == "pdflatex");
	assert(parsed.creationDate == SysTime.fromISOExtString("2022-04-13T08:40:11+02:00"));
	assert(parsed.modDate == SysTime.fromISOExtString("2022-04-13T08:40:11+02:00"));
	assert(parsed.page_size == "595.276 x 841.89 pts (A4)");
	assert(isClose(parsed.page_rot, 0));
	assert(parsed.pdf_version == "1.5");
}


private:

PdfInfo parsePdfInfo(string input) {
	import std.traits : FieldNameTuple;

	PdfLine[] lines = splitOutput(input);
	PdfInfo ret;

	foreach(line; lines) {
		static foreach(mem; FieldNameTuple!PdfInfo) {{
			enum memLower = mem.toLower();
			if(line.key == memLower) {
				alias MemType = typeof(__traits(getMember, PdfInfo, mem));
				static if(is(MemType == bool)) {
					__traits(getMember, ret, mem) = line.value == "yes";
				} else static if(is(MemType == string)) {
					__traits(getMember, ret, mem) = line.value;
				} else static if(is(MemType == long)) {
					__traits(getMember, ret, mem) = line.value.to!long();
				} else static if(is(MemType == double)) {
					__traits(getMember, ret, mem) = line.value.to!double();
				} else static if(is(MemType == SysTime)) {
					__traits(getMember, ret, mem) = parseSystime(line.value);
				}
			}
		}}
	}

	return ret;
}

struct PdfLine {
	string key;
	string value;
}

pure PdfLine[] splitOutput(string output) {
	return output.splitter("\n")
		.map!(line => splitLine(line))
		.filter!(n => !n.isNull())
		.map!(n => n.get())
		.array;
}

pure Nullable!PdfLine splitLine(string line) {
	ptrdiff_t firstColon = line.indexOf(":");
	if(firstColon == -1) {
		return Nullable!(PdfLine).init;
	}

	return PdfLine(line[0 .. firstColon].strip().replace(" ", "_").toLower()
			, line[firstColon + 1 .. $].strip()
			).nullable();
}

SysTime parseSystime(string datetime) {
	return SysTime.fromISOExtString(datetime);
}
