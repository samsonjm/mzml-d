# mzml-d
A library for parsing .mzML files used in mass spectrometry

## Installation

### DUB
```dub add mzml-d```

### Github
Clone the repository to your local computer.  You can then either move the required module(s) to your source folder, or add the cloned directory to your path (see the Dlang documentation).

## Use:
Example Usage:

```
import scans;
import mzmlparser;
import mzmlwriter;

void main()
{
    string myFileContents = read_file("testfiles/mzML.tiny.pwiz.1.1.mzML");
    ScanFile myScanFile = parze_mzml(myFileContents);
    // Use/change ScanFile object
    generate_mzML_content(myScanFile, "./output.mzML", encode_scans=true);
}
```
