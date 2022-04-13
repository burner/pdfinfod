# pdfinfod

pdfinfod is a wrapper around the linux util pdfinfo.
Calling the *extractPdfInfo* function as shown below
returns a struct instance of type *PdfInfo* containing
the data as listed below.
If the pdf file passed doesn't exist or pdfinfo is not
in the PATH an exception is thrown.

```dlang
module pdfinfod;

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

PdfInfo extractPdfInfo(string pdfFilename)
```
