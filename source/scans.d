/* Module for the scans class.
 * Stores all relevant information from .mzML files.
 * Note that the index from .mzML files isn't stored
 * as the byte number will change if there are any
 * changes to the file text.  The mzML writing 
 * module will calculate the index on its own.
 *
 * Author: Jonathan Samson
 * Date: 07-03-2024
 */

module scans;
import std.conv;
import std.algorithm;
import std.array;
import std.math.algebraic;
import mzmlparser;

/// Holds relevant information of the scan, can be used to create
/// .mzML or .mzXML files
class ScanFile
{
	MzML mzML;						/// MzML object representing the ScanFile's MzML
	uint sample_count;				/// number of samples in the file
	int scan_count;					/// number of scans in file
	real start_time; /// first retention time in file
	real end_time; 	 /// last retention time in file
	MSXScan[] scans; /// array to hold all scans

	this()
	{
		mzML = new MzML;
	}

	/// sets the number of signals in the current scan
	void set_scan_count()
	{
		scan_count = to!int(scans.length);
	}

	/// sets the start time of the current scan
	void set_start_time()
	{
		start_time = scans[0].retention_time;
	}

	/// Sets the end time of the current scan
	void set_end_time()
	{
		end_time = scans[scans.length - 1].retention_time;
	}

	/// Populates the MSXScan[] scans.
	void populate_scans()
	{
		import std.stdio;
		int spectrum_number = 0;
		foreach(spectrum; mzML.run.spectrumList.spectra)
		{
			++spectrum_number;
			MSXScan nextScan = new MSXScan;
			if(spectrum.id.split("scan=").length > 1)
			{
				nextScan.scan_number = spectrum.id.split("scan=")[1].split(" ")[0].to!int;
			}
			else if(spectrum.id.split("cycle=").length > 1)
			{
				nextScan.scan_number = spectrum.id.split("cycle=")[1].split(" ")[0].to!int;
			}
			else
			{
				nextScan.scan_number = spectrum_number;
			}
			foreach(cvParam; spectrum.cvParams)
			{
				switch(cvParam.name)
				{
					case "ms level":
					{
						nextScan.level = cvParam.value.to!uint;
						break;
					}
					case "positive scan":
					{
						nextScan.polarity = "+";
						break;
					}
					case "negative scan":
					{
						nextScan.polarity = "-";
						break;
					}
					case "centroid spectrum":
					{
						nextScan.centroided = 1;
						break;
					}
					case "base peak m/z":
					{
						nextScan.base_peak_mz = cvParam.value.to!float;
						break;
					}
					case "base peak intensity":
					{
						nextScan.base_peak_intensity = cvParam.value.to!float;
						break;
					}
					case "total ion current":
					{
						nextScan.total_ion_current = cvParam.value.to!float;
						break;
					}
					case "loweset observed m/z":
					{
						nextScan.low_mz = cvParam.value.to!float;
						break;
					}
					case "highest observed m/z":
					{
						nextScan.high_mz = cvParam.value.to!float;
						break;
					}
					default:
					{
					}
				}
			}
			foreach(scan; spectrum.scanList.scans)
			{
				foreach(cvParam; scan.cvParams)
				{
					switch(cvParam.name)
					{
						case "scan start time":
						{
							if(cvParam.unitName == "minute")
							{
								nextScan.retention_time = cvParam.value.to!real * 60;
							}
							else
							{
								nextScan.retention_time = cvParam.value.to!real;
							}
							break;
						}
						default:
						{
						}
					}
				}
				foreach(scanWindow; scan.scanWindowList.scanWindows)
				{
					foreach(cvParam; scanWindow.cvParams)
					{
						switch(cvParam.name)
						{
							case "scan window lower limit":
							{
								nextScan.scan_window_lower_limit ~= cvParam.value.to!float;
								break;
							}
							case "scan window upper limit":
							{
								nextScan.scan_window_lower_limit ~= cvParam.value.to!float;
								break;
							}
							default:
							{
							}
						}
					}
				}
			}
			int precursor_count = 0;
			int precursor_found = 0;
			foreach(precursor; spectrum.precursorList.precursors)
			{
				if(nextScan.level > 1)
				{
					if(precursor.spectrumRef.split("scan=").length > 1)
					{
						int precursor_scan_number = precursor.spectrumRef.split("scan=")[1].split(" ")[0].to!int;
						for(int scan_index=0; scan_index<scans.length - 1; ++scan_index)
						{
							if(scans[scans.length - (scan_index + 1)].scan_number == precursor_scan_number)
							{
								++precursor_found;
								nextScan.parent_scan ~= scans[scans.length - (scan_index + 1)];
								break;
							}
						}
					}
					foreach(cvParam; precursor.isolationWindow.cvParams)
					{
						switch(cvParam.name)
						{
							case "isolation window target m/z":
							{
								real parent_mz = cvParam.value.to!real;
								real mass_difference = 1_000_000_000_000; /// Unreasonably high value
								real closest_parent_mass = 0;
								if(precursor_count == 0)
								{
									nextScan.parent_peak = 	parent_mz;
									break;
								}
								foreach(mass; nextScan.parent_scan[precursor_count].peaks.keys)
								{
									if(parent_mz == mass)
									{
										closest_parent_mass = mass;
										break;
									}
									else
									{
										const real current_difference = abs(parent_mz - mass);
										if(current_difference < mass_difference)
										{
											closest_parent_mass = mass;
											mass_difference = current_difference;
										}
									}
								}
								nextScan.parent_peak = closest_parent_mass;
								break;
							}
							case "isolation window lower offset":
							{
								nextScan.iso_window_lower_offset = cvParam.value.to!float;
								break;
							}
							case "isolation window upper offset":
							{
								nextScan.iso_window_upper_offset = cvParam.value.to!float;
								break;
							}
							default:
							{
							}
						}
					}
					for(int selected_ion_count=0; selected_ion_count < precursor.selectedIonList.count; ++selected_ion_count)
					{
						foreach(cvParam; precursor.selectedIonList.selectedIons[selected_ion_count].cvParams)
						{
							switch(cvParam.name)
							{
								case "selected ion mz":
								{
									nextScan.selected_ion_mz ~= cvParam.value.to!float;
									break;
								}
								case "peak intensity":
								{
									nextScan.selected_ion_intensity ~= cvParam.value.to!float;
									break;
								}
								default:
								{
								}
							}
						}
					}
				}
				else
				{
				}
				++precursor_count;
			}
			real[] mz_array;
			real[] intensity_array;
			foreach(binaryDataArray; spectrum.binaryDataArrayList.binaryDataArrays)
			{
				int bit_size;
				string compression_type;
				string array_type;
				foreach(cvParam; binaryDataArray.cvParams)
				{
					switch(cvParam.name)
					{
						case "64-bit float":
						{
							bit_size = 64;
							break;
						}
						case "32-bit float":
						{
							bit_size = 32;
							break;
						}
						case "no compression":
						{
							compression_type = "none";
							break;
						}
						case "zlib compression":
						{
							compression_type = "zlib";
							break;
						}
						case "m/z array":
						{
							array_type = "mz";
							break;
						}
						case "intensity array":
						{
							array_type = "int";
							break;
						}
						default:
						{
						}
					}
				}
				if(array_type == "int")
				{
						intensity_array = decode_mzml_string(
								binaryDataArray.binary.encodedData,
								compression_type,
								bit_size);
				}
				else if (array_type == "mz")
				{
						mz_array = decode_mzml_string(
								binaryDataArray.binary.encodedData, 
								compression_type,
								bit_size);
				}
			}
			for(int peak_count=0; peak_count<mz_array.length; ++peak_count)
			{
				nextScan.peaks[mz_array[peak_count]] = intensity_array[peak_count];
			}
			nextScan.set_peaks_count();
			nextScan.set_detected_mz_limits();
			scans ~= nextScan;
		}
	}
}

/// Holds information relevant for a MS1 scan.
class MS1Scan
{
	uint scan_number;			/// scan number in current chromatogram
	uint level;					/// ms level of the scan
	uint peaks_count;			/// number of peaks present in scan
	string polarity;			/// polarity of the scan
	int centroided;				/// whether the scan is centroided
	real retention_time;		/// retention time of scan
	float start_mz; 			/// lowest mz to look for in scan
	float end_mz;				/// highest mz to look for in scan
	float low_mz;				/// minimum mz in scan
	float high_mz;				/// maximum mz in scan
	float base_peak_mz;			/// mz of scan's base peak
	float base_peak_intensity;	/// base peak intensity in this scan
	float total_ion_current;	/// total ion current in the scan
	real[real] peaks;			/// mz:intensity of signals in the scan
	float[] scan_window_upper_limit; /// upper limit of the scan window
	float[] scan_window_lower_limit; /// lower limit of the scan window

	real get_peak_intensity(real my_peak)
	/**
	 * Gives the peak intensity of the set peak in the scan.
	 * Params:
	 *	my_peak = The peak of interest.
	 * Returns:
	 *	intensity = This scan's intensity of my_peak.
	 */
	{
		const real* peak_intensity = (my_peak in peaks);
		real intensity = 0;
		if (peak_intensity !is null)
			intensity = *peak_intensity;
		return intensity;
	}

	/** 
	 * Either adds a peak or changes the intensity of a peak.
	 * Params:
	 *	mz = the mass to charge ratio of the new peak.
	 *	intensity = the intensity of the new peak.
	 */
	void add_peak(real mz, real intensity)
	{
		peaks[mz] = intensity;
		set_base_peak_variables();
		set_peaks_count();
	}

	/** Sets the base_peak_mz and base_peak_intensity variables.
	 */
	void set_base_peak_variables()
	{
		real max_int = 0;
		real max_int_mz;
		foreach(mz, intensity; peaks)
		{
			if (intensity > max_int)
			{
				max_int = intensity;
				max_int_mz = mz;
			}
		}
		base_peak_mz = max_int_mz;
		base_peak_intensity = max_int;	
	}

	void set_peaks_count()
	/* Sets the peaks_count variable.
	 */
	{
		peaks_count = to!uint(peaks.length);
	}

	void set_detected_mz_limits()
	/* Sets the low_mz and high_mz variables
	 */
	{
		if(peaks.keys.length != 0)
		{
			low_mz = minElement(peaks.keys);
			high_mz = maxElement(peaks.keys);
		}
	}

}
unittest
{
	import std.math.operations;
	MSXScan test = new MSXScan;
	real[real] peaks = [
		51.46782684: 1_460.6981201172,
		75.82749939: 1_671.7169189453,
		75.86730194: 1_605.3143310547,
		100.1144104: 1_462.4990234375,
		101.5387802: 1_490.517578125,
		107.7608643: 1_808.1832275391,
		118.443428: 1_619.8599853516,
		130.0875244: 37_516.33203125,
		146.9610138: 1_678.8117675781,
		171.1526642: 1_760.8597412109,
		199.1815948: 35_382.921875,
		243.1713562: 107_272.828125,
		244.1736908: 8_717.1875
	];
	test.peaks = peaks;
	test.scan_number = 1;
	assert(test.scan_number == 1);
	test.level = 1;
	assert(test.level == 1);
	test.set_peaks_count();
	assert(test.peaks_count == peaks.length);
	test.polarity = "+";
	assert(test.polarity == "+");
	test.polarity = "-";
	assert(test.polarity == "-");
	assert(test.polarity != "+");
	test.centroided = 1;
	assert(test.centroided == 1);
	test.retention_time = 100.110;
	assert(isClose(test.retention_time, 100.110));
	test.start_mz = 50;
	assert(test.start_mz == 50);
	test.end_mz = 250;
	assert(test.end_mz == 250);
	test.set_detected_mz_limits();
	assert(isClose(test.low_mz, 51.46782684));
	assert(isClose(test.high_mz, 244.1736908));
	test.set_base_peak_variables;
	assert(isClose(test.base_peak_mz, 243.1713562));
	assert(isClose(test.base_peak_intensity, 107_272.828125));
	test.total_ion_current = 1_000_000_000.12345;
	assert(isClose(test.total_ion_current, 1_000_000_000.12345));
	assert(test.peaks == peaks);
	test.add_peak(56.12356, 5_235.12359);
	peaks[56.12356] = 5_235.12359;
	assert(isClose(test.get_peak_intensity(56.12356), 5_235.12359));
	assert(test.peaks == peaks);
}

/// A Scan that includes parent data and collision energy.
class MSXScan : MS1Scan
{
	MSXScan[] parent_scan; /// Scan of parent peak
	real parent_peak; /// mz of parent peak, may be same as selected_ion_mz
	float iso_window_upper_offset; /// upper m/z offset for iso
	float iso_window_lower_offset; /// lower m/z offset for iso
	float[] selected_ion_mz; /// ions selected for fragmentation,
	float[] selected_ion_intensity; /// intensities of the selected ions

	real get_parent_rt(int parent_scan_number)
	/* Gives the retention time from the parent scan for this MSX.
	 * Arguments:
	 *  parent_scan_number = the index of the parent scan wanted (0 based);
	 * Returns:
	 *	this.parent_scan.get_rt() - The relevant parent rt.
	 */
	{
		return parent_scan[parent_scan_number].retention_time;
	}
}
unittest
{
	import std.math.operations;
	MSXScan parent = new MSXScan;
	parent.retention_time = 600.2;
	Scan notparent = new Scan;
	MSXScan test = new MSXScan;
	real[real] peaks = [
		51.46782684: 1_460.6981201172,
		75.82749939: 1_671.7169189453,
		75.86730194: 1_605.3143310547,
		100.1144104: 1_462.4990234375,
		101.5387802: 1_490.517578125,
		107.7608643: 1_808.1832275391,
		118.443428: 1_619.8599853516,
		130.0875244: 37_516.33203125,
		146.9610138: 1_678.8117675781,
		171.1526642: 1_760.8597412109,
		199.1815948: 35_382.921875,
		243.1713562: 107_272.828125,
		244.1736908: 8717.1875
	];
	test.level = 2;
	assert(test.level == 2);
	test.retention_time = 100.110;
	assert(isClose(test.retention_time, 100.110));
	test.peaks = peaks;
	assert(test.peaks == peaks);
	test.add_peak(56.12356, 5235.12359);
	peaks[56.12356] = 5_235.12359;
	assert(test.get_peak_intensity(56.12356) == 5_235.12359);
	assert(test.peaks == peaks);
	test.parent_peak = 244.1736908;
	assert(test.parent_peak == 244.1736908);
	test.parent_scan ~= parent;
	assert(test.parent_scan[0] == parent);
	assert(test.parent_scan[0] != notparent);
	assert(isClose(test.get_parent_rt(0), 600.2));
	test.total_ion_current = 1_800_000;
	assert(test.total_ion_current == 1_800_000);
}

///List of controlled vocabulary variables
class CVList
{
	int count;	/// Number of CVs in the list
	CV[] cvs;	/// the CVs in the list

	/// Sets the count to the number of CVs
	void set_count()
	{
		count = cvs.length.to!int;
	}
}

/// Controlled Vocabulary class
class CV
{
	string URI;	/// the URI of the CV
	string fullName;	/// The name of the CV
	string id;	/// the ID of the CV
	string vers;	/// the version of the CV
}

/// Summary of the different types of spectra to be expected
class FileContent
{
	ReferenceableParamGroupRef[] refParamRef; /// References of Param groups
	CVParam[] cvParams; /// list of controlled vocabularies
	UserParam[] userParams; /// list of user parameters
}

///Description of the source file
class SourceFile
{
	string id;	/// identifier for the file
	string location;	/// URI-formatted location
	string name;	/// name of the source file
	ReferenceableParamGroupRef[] refParamRef; /// References of Param groups
	CVParam[] cvParams; /// list of controlled vocabularies
	UserParam[] userParams; /// list of user parameters
}

/// List of SourceFiles
class SourceFileList
{
	SourceFile[] sourceFiles;	/// List of source files
	int count;	/// Number of sourceFiles in the list

	/// Sets the count to the number of source files
	void set_count()
	{
		count = sourceFiles.length.to!int;
	}
}

/// Structure allowing use of cvParam or userParam or reference to a set of these
class Contact
{
	ReferenceableParamGroupRef[] refParamRef; /// References of Param groups
	CVParam[] cvParams; /// list of controlled vocabularies
	UserParam[] userParams; /// list of user parameters
}

/// Information pertaining to the entire mzML file
class FileDescription
{
	FileContent fileContent;	/// Summarizes spectra present
	SourceFileList sourceFileList;	/// list of source files
	Contact[] contacts;	/// Allows use of CVparam and userParam

	this()
	{
		sourceFileList = new SourceFileList;
		fileContent = new FileContent;
	}
}

/// Reference from the referenceableParamGroup
class ReferenceableParamGroupRef
{
	string reference; /// The refence to the ID attribute in referenceableParamGroup
}

/// Controlled Vocabulary parameters
class CVParam
{
	string accession;	/// accession code for the CV
	string cvRef;		/// reference to CV id attribute
	string name;		/// name for the parameter
	string unit_accession;	/// optional cv accession number for the unit term
	string unitCVRef;	/// cvref of the unit_accession 
	string unitName;	/// name of the unit_accession
	string value;		/// optional; value of the parameter
}

/// User-based parameters
class UserParam
{
	string name;	/// name for the parameter
	string type;	/// optional, datatype of the parameter
	string unitAccession;	/// optional, CV accession number for the unit term
	string unitCvRef;	/// CV ref of the unit
	string unitName;	/// optional, name of the unit
	string value;	/// optional, value of the parameter
}

/// Collection of CVParam and UserParam that can be referenced elsewhere
class ReferenceableParamGroup
{
	string id;	/// Identifier used to reference this param group
	CVParam[] cvParams; /// list of controlled vocabularies
	UserParam[] userParams; /// list of user parameters
}

/// A list of ReferenceableParamGroups
class ReferenceableParamGroupList
{
	ReferenceableParamGroup[] refParamGroups; /// list of ReferenceableParamGroups
	int count;	/// Number of refParamGroups in the list

	/// Sets the count to the number of referenceableParamGroups
	void set_count()
	{
		count = refParamGroups.length.to!int;
	}
}

/// Description of the sample used to generate the dataset
class Sample
{
	string id;	/// Unique identifier to reference this sample
	string name;	/// Optional name for sample description
	ReferenceableParamGroupRef[] refParamRef; /// References of Param groups
	CVParam[] cvParams; /// list of controlled vocabularies
	UserParam[] userParams; /// list of user parameters
}

/// List of samples
class SampleList
{
	Sample[] samples;	/// List of samples
	int count;	/// Number of samples in the list

	/// Sets the count to the number of samples
	void set_count()
	{
		count = samples.length.to!int;
	}
}

/// A piece of software
class Software
{
	string id;	/// unique identifier for this software
	string vers;	/// version of the software
	ReferenceableParamGroupRef[] refParamRef; /// References of Param groups
	CVParam[] cvParams; /// list of controlled vocabularies
	UserParam[] userParams; /// list of user parameters
}

/// List of softwares used to acquire or process the file
class SoftwareList
{
	Software[] softwares;	/// List of softwares
	int count;	/// Number of softwares in the list

	/// Sets the count to the number of softwares
	void set_count()
	{
		count = softwares.length.to!int;
	}
}

/// Description of default peak processing method
class ProcessingMethod
{
	uint order;	/// The position in the processing order
	string softwareRef;	/// The id of the SoftwareType
	ReferenceableParamGroupRef[] refParamRef; /// References of Param groups
	CVParam[] cvParams; /// list of controlled vocabularies
	UserParam[] userParams; /// list of user parameters
}

/// Description of the way that software was used
class DataProcessing
{
	string id;	/// unique identifier for this data process
	ProcessingMethod[] processingMethods;	/// list of processing methods
}

/// List of data processing applied to this data
class DataProcessingList
{
	DataProcessing[] dataProcessings;	/// list of data processing steps applied
	int count;	/// Number of data processing steps in the list

	/// Sets the count to the number of data processing steps
	void set_count()
	{
		count = dataProcessings.length.to!int;
	}
}

/// Reference to a previously defined source file
class SourceFileRef
{
	string reference;	/// id of the appropriate sourceFile
}

/// List with source files for acquisition settings
class SourceFileRefList
{
	SourceFileRef[] sourceFileRefs;	/// list of source files for acquisition settings
	int count;	/// Number of source files in the list

	/// Sets the count to the number of source files
	void set_count()
	{
		count = sourceFileRefs.length.to!int;
	}

}

/// allows use of cvParam or userParam or reference to a paramGroup
class Target
{
	ReferenceableParamGroupRef[] refParamRef; /// References of Param groups
	CVParam[] cvParams; /// list of controlled vocabularies
	UserParam[] userParams; /// list of user parameters
}	

/// Target list (or inclusion list) configured prior to run
class TargetList
{
	Target[] targets;	/// list of targets
	int count;	/// Number of targets in the list

	/// Sets the count to the number of targets
	void set_count()
	{
		count = targets.length.to!int;
	}
}

/// Description of acquisition settings of the instrument prior to the start of the run
class ScanSettings
{
	string id;	/// Unique identifier for this acquisition setting	
	ReferenceableParamGroupRef[] refParamRef; /// References of Param groups
	CVParam[] cvParams; /// list of controlled vocabularies
	UserParam[] userParams; /// list of user parameters
	SourceFileRefList sourceFileRefList; /// list with source files for acquisition settings
	TargetList targetList;	/// list of targets configured prior to the run

	this()
	{
		sourceFileRefList = new SourceFileRefList;
		targetList = new TargetList;
	}
}

/// List of acquisition settings applied prior to data acquisition
class ScanSettingsList
{
	ScanSettings[] scanSettings;	/// List of scan settings
	int count;	/// Number of scan settings in the list

	/// Sets the count to the number of scan settings
	void set_count()
	{
		count = scanSettings.length.to!int;
	}
}

/// A source component
class Source
{
	uint order;	/// Position in the order of sources encountered
	ReferenceableParamGroupRef[] refParamRef; /// References of Param groups
	CVParam[] cvParams; /// list of controlled vocabularies
	UserParam[] userParams; /// list of user parameters
}

/// A mass analyzer (or filter) component
class Analyzer
{
	uint order;	/// Position in the order of analyzers encountered
	ReferenceableParamGroupRef[] refParamRef; /// References of Param groups
	CVParam[] cvParams; /// list of controlled vocabularies
	UserParam[] userParams; /// list of user parameters
}

/// A detector component
class Detector
{
	uint order;	/// Position in the order of detectors encountered
	ReferenceableParamGroupRef[] refParamRef; /// References of Param groups
	CVParam[] cvParams; /// list of controlled vocabularies
	UserParam[] userParams; /// list of user parameters
}

/// List with different components used in the mass spectrometer
class ComponentList
{
	Source[] sources;	/// List of sources used
	Analyzer[] analyzers;	/// List of analyzers used
	Detector[] detectors;	/// List of detectors used
	int count;	/// Number of components in this list

	/// Sets the count to the number of components
	void set_count()
	{
		count = sources.length.to!int +
				analyzers.length.to!int +
				detectors.length.to!int;
	}
}

/// Reference to a previously defined software element
class SoftwareRef
{
	string reference;	/// Reference to the software
}

/// Description of a hardware configuration of the mass spectrometer
class InstrumentConfiguration
{
	string id;	/// identifier for this instrument configuration
	string scanSettingsRef;	/// optional, previously set identifier for scanSetting
	ReferenceableParamGroupRef[] refParamRef; /// References of Param groups
	CVParam[] cvParams; /// list of controlled vocabularies
	UserParam[] userParams; /// list of user parameters
	ComponentList componentList; /// List of mass spectrometer components
	SoftwareRef softwareRef;	/// reference to a previously defined software element

	this()
	{
		componentList = new ComponentList;
		softwareRef = new SoftwareRef;
	}
}

/// List of instrument configurations
class InstrumentConfigurationList
{
	InstrumentConfiguration[] instrumentConfigurations;	/// List of instrument configurations
	int count;	/// Number of instrument configurations in the list

	/// Sets the count to the number of instrument configurations
	void set_count()
	{
		count = instrumentConfigurations.length.to!int;
	}
}

/// Range of m/z values over which an instrument scans to aquire a spectrum
class ScanWindow
{
	ReferenceableParamGroupRef[] refParamRef; /// References of Param groups
	CVParam[] cvParams; /// list of controlled vocabularies
	UserParam[] userParams; /// list of user parameters
}

/// Container for a list of scan windows
class ScanWindowList
{
	ScanWindow[] scanWindows; /// List of scan windows
	int count;	/// Number of scan windows in the list

	/// Sets the count to the number of scan windows
	void set_count()
	{
		count = scanWindows.length.to!int;
	}
}

/// Scan or acquisition from the raw file used to create this peak list
class Scan
{
	string externalSpectrumID;	/// optional for scans external to this document, id of a spectrum in sourceFileRef
	string instrumentConfigurationRef;	/// optional, references id of appropriate instrument config
	string sourceFileRef;	/// optioanl, references id of a sourceFile of an external document
	string spectrumRef;	///optional, id of scans local to this file
	ReferenceableParamGroupRef[] refParamRef; /// References of Param groups
	CVParam[] cvParams; /// list of controlled vocabularies
	UserParam[] userParams; /// list of user parameters
	ScanWindowList scanWindowList;	/// list of scan windows

	this()
	{
		scanWindowList = new ScanWindowList;
	}
}

/// List of scans
class ScanList
{
	ReferenceableParamGroupRef[] refParamRef; /// References of Param groups
	CVParam[] cvParams; /// list of controlled vocabularies
	UserParam[] userParams; /// list of user parameters
	Scan[] scans;	/// list of scans
	int count;	/// Number of scans in the list

	/// Sets the count to the number of scans
	void set_count()
	{
		count = scans.length.to!int;
	}
}

/// isolation window to isolate ions
class IsolationWindow
{
	ReferenceableParamGroupRef[] refParamRef; /// References of Param groups
	CVParam[] cvParams; /// list of controlled vocabularies
	UserParam[] userParams; /// list of user parameters
}

/// Allows use of cvParam, userParam, or paramGroupRef
class SelectedIon
{
	ReferenceableParamGroupRef[] refParamRef; /// References of Param groups
	CVParam[] cvParams; /// list of controlled vocabularies
	UserParam[] userParams; /// list of user parameters
}

/// List of selected ions
class SelectedIonList
{
	SelectedIon[] selectedIons;	/// List of selected ions
	int count;	/// Number of selected ions in the list

	/// Sets the count to the number of selected ions
	void set_count()
	{
		count = selectedIons.length.to!int;
	}
}

/// The type and energy level used for activation
class Activation
{
	ReferenceableParamGroupRef[] refParamRef; /// References of Param groups
	CVParam[] cvParams; /// list of controlled vocabularies
	UserParam[] userParams; /// list of user parameters
}

/// The method of precursor ion selection and activation
class Precursor
{
	string externalSpectrumID;	/// optional, for external spectra, id in the document indicated by sourceFileRef
	string sourceFileRef;	/// optional, external sourceFile holding precursor data
	string spectrumRef;	/// optional, for local precursors, references id attribute to precursor spectrum
	IsolationWindow isolationWindow;	/// isolation window to isolate ions
	SelectedIonList selectedIonList;	/// List of selected ions
	Activation activation;	/// The type and energy level used for activation

	this()
	{
		isolationWindow = new IsolationWindow;
		selectedIonList = new SelectedIonList;
		activation = new Activation;
	}
}

/// List of precursor isolations
class PrecursorList
{
	Precursor[] precursors;	/// List of precursors
	int count;	/// Number of precursors in the list

	/// Sets the count to the number of precursors
	void set_count()
	{
		count = precursors.length.to!int;
	}
}

/// Method of product ion selection and activation in a scan
class Product
{
	IsolationWindow isolationWindow;	/// isolation window to isolate ions

	this()
	{
		isolationWindow = new IsolationWindow;
	}
}

/// List of product isolations
class ProductList
{
	Product[] products;	/// List of product isolations
	int count;	/// Number of products in the list

	/// Sets the count to the number of products
	void set_count()
	{
		count = products.length.to!int;
	}
}

/// Encoded binary data.  mzML is always little endian byte order
class Binary
{
	string encodedData;	/// encoded binary data
}

/// Data point arrays for defailt data arrays (m/z, intensity, time) and meta data arrays
class BinaryDataArray
{
	uint arrayLength;	/// NOT DEFAULT DATA ARRAY, overrides defaultArrayLength in SpectrumType
	string dataProcessingRef;	/// NOT DEFAULT DATA ARRAY, references id attribute of the appropriate dataProcessing
	uint encodedLength;	/// encoded length of the binary data array
	ReferenceableParamGroupRef[] refParamRef; /// References of Param groups
	CVParam[] cvParams; /// list of controlled vocabularies
	UserParam[] userParams; /// list of user parameters
	Binary binary;	/// encoded binary data

	this()
	{
		binary = new Binary;
	}
}

/// List of binary data arrays
class BinaryDataArrayList
{
	BinaryDataArray[] binaryDataArrays;	/// list of binary data arrays
	int count;	/// Number of binary data arrays in the list

	/// Sets the count to the number of binary data arrays
	void set_count()
	{
		count = binaryDataArrays.length.to!int;
	}
}

/// Structure that captures the generation of a peak list
class Spectrum
{
	string dataProcessingRef;	/// optional, references the id of the appropriate dataProcessing
	int defaultArrayLength;	/// Default length of binary data arrays contained in the element
	string id;	/// Native identifier for a spectrum
	uint index;	/// zero-based consecutive index of the spectrum in the SpectrumList
	string sourceFileRef;	/// optional, references the id of the appropriate sourceFile
	string spotID;	/// optional, identifier for the spot from wihch the spectrum was derived (eg. from MALDI)
	ReferenceableParamGroupRef[] refParamRef; /// References of Param groups
	CVParam[] cvParams; /// list of controlled vocabularies
	UserParam[] userParams; /// list of user parameters
	ScanList scanList;	/// List of scans
	PrecursorList precursorList;	/// List of precursors
	ProductList productList;	/// List of products
	BinaryDataArrayList binaryDataArrayList;	/// List of binary data arrays

	this()
	{
		scanList = new ScanList;
		precursorList = new PrecursorList;
		productList = new ProductList;
		binaryDataArrayList = new BinaryDataArrayList;
	}
}

/// A list of spectra
class SpectrumList
{
	string defaultDataProcessingRef;	/// default data processing reference for spectrum list
	Spectrum[] spectra;	/// list of spectra
	int count;	/// Number of spetctra in the list

	/// Sets the count to the number of spectra
	void set_count()
	{
		count = spectra.length.to!int;
	}
}

/// A single chromatogram
class Chromatogram
{
	string dataProcessingRef;	/// optional, references the id of the appropriate dataProcessing
	int defaultArrayLength;	/// Default length of bonary data arrays contained in this element
	string id;	/// Unique identifier for this chromatogram
	uint index;	/// zero-based index for this chromatogram in the chromatogram list
	ReferenceableParamGroupRef[] refParamRef; /// References of Param groups
	CVParam[] cvParams; /// list of controlled vocabularies
	UserParam[] userParams; /// list of user parameters
	BinaryDataArrayList binaryDataArrayList;	/// List of binary data arrays

	this()
	{
 		binaryDataArrayList = new BinaryDataArrayList;
	}
}

/// All chromatogragms in this run
class ChromatogramList
{
	string defaultDataProcessingRef;	/// optional, references the id of the appropriate dataProcessing
	Chromatogram[] chromatograms;	/// list of chromatograms
	int count;	/// Number of chromatograms in the list

	/// Sets the count to the number of chromatograms
	void set_count()
	{
		count = chromatograms.length.to!int;
	}
}

/// A single, consecutive and coherent set of scans on an instrument
class Run
{
	string defaultInstrumentConfigurationRef;	/// id of the default instrument configuration
	string defaultSourceFileRef;	/// optional, references id of the default source file
	string id;	/// Unique identifier for this run
	string sampleRef;	/// optional, references the id of the appropriate sample
	string startTimeStamp;	/// optional, start timestamp of the run in UT
	ReferenceableParamGroupRef[] refParamRef; /// References of Param groups
	CVParam[] cvParams; /// list of controlled vocabularies
	UserParam[] userParams; /// list of user parameters
	SpectrumList spectrumList;	/// list of spectrums
	ChromatogramList chromatogramList;	/// list of chromatograms

	this()
	{
		spectrumList = new SpectrumList;
		chromatogramList = new ChromatogramList;
	}
}

/// Root element for mzML schema.
class MzML
{
	string accession;	/// optional, accession number for the mzML document for storage
	string id;	/// optional, id for the mzML document used for referencing from external files
	string vers;	/// the version of this mzML document
	CVList cvList; /// The cvList
	FileDescription fileDescription;	/// description of the file
	ReferenceableParamGroupList referenceableParamGroupList;	/// list of referenceableParamGroups
	SampleList sampleList;	/// List of samples
	SoftwareList softwareList;	/// List of software ised to acquire and/or process the data
	ScanSettingsList scanSettingsList;	/// List of descriptions of acquisition settings applied prior to acquisition
	InstrumentConfigurationList instrumentConfigurationList;	/// List of instrument configurations
	DataProcessingList dataProcessingList;	/// List of data processing applied to this data
	Run run;	/// A single, coherent set of scans on the instrument

	this()
	{
		cvList = new CVList;
		fileDescription = new FileDescription;
		referenceableParamGroupList = new ReferenceableParamGroupList;
		sampleList = new SampleList;
		softwareList = new SoftwareList;
		scanSettingsList = new ScanSettingsList;
		instrumentConfigurationList = new InstrumentConfigurationList;
		dataProcessingList = new DataProcessingList;
		run = new Run;
	}
}
