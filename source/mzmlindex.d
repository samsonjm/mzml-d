//          Copyright Jonathan Matthew Samson 2020 - 2024.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          https://www.boost.org/LICENSE_1_0.txt)


/* Module for the MzMLIndex class.
 * Stores information from the indexList.
 *
 * Author: Jonathan Samson
 * Date: 07-03-2024
 */
module mzmlindex;

/// Stores information from the mzML indexList.
/// Indices correspond to the spectrum/chromatogram
/// location within the index, not the spectrum/
/// chromatogram number.
class MzmlIndex
{
	int[int] spectrumIndex; // The spectrum index and byte location
	int[int] chromatogramIndex; // The chromatogram index and byte location
}
