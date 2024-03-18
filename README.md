# mzml-d
A library for parsing .mzML files used in mass spectrometry

## Installation

### DUB
Use

```dub add mzml-d```

### Github
Clone the repository to your local computer.  You can then either move the required module(s) to your source folder, or add the cloned directory to your path (see the Dlang documentation).

## Use:
Example Usage:

```
import mzmld.scans;
import mzmld.mzmlparser;

void main()
{
    string myFileContents = read_file("testfile.mzML");
    ScanFile myScanFile = parze_mzml(myFileContents);
}
```
