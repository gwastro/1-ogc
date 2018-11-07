# 1-OGC: The first open gravitational-wave catalog of binary mergers from analysis of public Advanced LIGO data
**Alexander H. Nitz<sup>1,2</sup>, Collin Capano<sup>1,2</sup>, Alex B. Nielsen<sup>1,2</sup>, Steven Reyes<sup>3</sup>, Rebecca White<sup>4,3</sup>, Duncan A. Brown<sup>3</sup>, Badri Krishnan<sup>1,2</sup>**


 <sub>1.[Albert-Einstein-Institut, Max-Planck-Institut for Gravitationsphysik, D-30167 Hannover, Germany](http://www.aei.mpg.de/obs-rel-cos)</sub>  
 <sub>2.Leibniz Universitat Hannover, D-30167 Hannover, Germany</sub>  
 <sub>3. Department of Physics, Syracuse University, Syracuse, NY 13244, USA</sub>  
 <sub>4. Fayetteville-Manlius High School, Manlius, NY 13104, USA</sub>  


## Introduction ##

This repository contains the first Open Gravitational-wave Catalog (1-OGW), which is obtained by using the public data from Advanced LIGO's first observing run to search for compact-object binary mergers. Our analysis is based on new methods that improve the separation between signals and noise in matched-filter searches for gravitational waves from the merger of compact objects. 

We make available our complete catalog of events, including the sub-threshold population of candidates. The catalog contains approximately 150,000 candidate events. We note that since the vast majority of the events in the catalog are likely to be noise, we have provided information to rank and select candidate events. The three most significant signals in our catalog correspond to the binary black hole mergers  [GW150914](https://journals.aps.org/prl/abstract/10.1103/PhysRevLett.116.061102), [GW151226](https://journals.aps.org/prl/abstract/10.1103/PhysRevLett.116.241103), and [LVT151012](https://journals.aps.org/prd/abstract/10.1103/PhysRevD.93.122003), respectively. We observe these signals at a true discovery rate of 99.92%. We find that LVT151012 alone has a 97.6% probability of being astrophysical in origin. No other significant binary black hole candidates are found, nor did we observe any significant binary neutron star or neutron star--black hole candidates.

The catalog is stored in the file '1-OGC.hdf'. There are a variety of tools to access [hdf files](https://www.hdfgroup.org/) from numerous computing languages. Here we will focus on access through python and [h5py](www.h5py.org).

## Analysis Details ##
Details of the analysis are available in this [preprint paper](https://arxiv.org/abs/1811.01921) and the configuration files needed to create the analysis workflows are provided in the [workflow/configuration](https://github.com/gwastro/1-ogc/tree/master/workflow/configuration) directory.

## Accessing the Catalog: 1-OGC.hdf ##

There are two datasets within the file, `/complete` and `/bbh`. The `complete` set is the full dataset from our analysis. The `bbh` set includes BBH candidates from a select portion of the analysis. See the 1-OGC paper for additional information. 


```python
import h5py

catalog = h5py.File('./1-OGC.hdf', 'r')

# Get a numpy structured array of the candidate event properties.
all_candidates = catalog['complete']
bbh_candidates = catalog['bbh']

# Accessing a column by name
ranking_values = all_candidates['stat']

# Selecting parts of the catalog
region = all_candidates['mass1'] + all_candidates['mass2'] < 4
lowmass_candidates = all_candidates[region]

```


##### File format #####
Both datasets are structured arrays which have the following named columns. Some of these columns give information specific to either the 
LIGO Hanford or Livingston detectors. Where this is the case, the name of the column is prefixed with either a `H1` or `L1`.

| Key           | Description                                                                                                                         |
|---------------|-------------------------------------------------------------------------------------------------------------------------------------|
| name          | The designation of the candidate event. This is of the form 150812+12:23:04UTC.                                                     |
| jd | Julian Date of the average between the Hanford and Livingston observed end times |
| far           | The rate of false alarms with a ranking statistic as large or larger than this event. The unit is yr^-1.                                                                                                           |
| stat          | The value of the ranking statistic for this candidate event.                                                                                       |
| mass1         | The component mass of one compact object in the template waveform which found this candidate. Units in detector frame solar masses. |
| mass2         | The component mass of the template waveform which found this candidate. Units in detector frame solar masses.                       |
| spin1z        | The dimensionless spin of one of the compact objects for the template waveform which found this candidate.                                                                                                                                  |
| spin2z        | The dimensionless spin of one of the compact objects for the template waveform which found this candidate.                                                                                                                                    |
| {H1/L1}_end_time   | The time in GPS seconds when a fiducial point in the signal passes throught the detector. Typically this is near the time of merger.                                                                                                                              |                                                                                                                           |
| {H1/L1}_snr        | The amplitude of the complex matched filter signal-to-noise observed.                                                                                                                                    |
| {H1/L1}_coa_phase        | The phase (angle) of the complex matched filter signal-to-noise observed.                                                          |
| {H1/L1}_reduced_chisq |  Value of the signal consistency test defined in this [paper](https://arxiv.org/abs/gr-qc/0405045). This is not calculated for all candidate events. In this case a value of 0 is substituted.                                                                                                                                  |
| {H1/L1}_sg_chisq      |  Value of the signal consistency test defined in this [paper](https://arxiv.org/abs/1709.08974). This is not calculated for all candidate events. In this case a value of 1 is substituted.                                                                                                                     |
| {H1/L1}_sigmasq       |   The integral of the template waveform divided by the power spectral density.

The `/bbh` dataset also has the following additional columns.

| Key           | Description                                                                                                                         |
|---------------|-------------------------------------------------------------------------------------------------------------------------------------|
| pastro |     The probability that this BBH candidate is of astrophysical origin.                                        |
| tdr |        The fraction of signals with this ranking statistic and above which are astrophysical in origin.                                               |


## License and Citation

![Creative Commons License](https://i.creativecommons.org/l/by-sa/3.0/us/88x31.png "Creative Commons License")

This work is licensed under a [Creative Commons Attribution-ShareAlike 3.0 United States License](http://creativecommons.org/licenses/by-sa/3.0/us/).

We encourage use of these data in derivative works. If you use the material provided here, please cite the paper using the reference:

```
@article{Nitz:2018XXX,
      author         = "Alexander H. Nitz, Collin Capano, Alex B. Nielsen,
                        Steven Reyes, Rebecca White, Duncan A. Brown and
                        Badri Krishnan",
      title          = "{1-OGC: The first open gravitational-wave catalog of
                         binary mergers from analysis of public Advanced LIGO data}",
      year           = "2018",
      eprint         = "1811.01921",
      archivePrefix  = "arXiv",
      primaryClass   = "gr-qc",
      SLACcitation   = "%%CITATION = ARXIV:1811.01921;%%"
}
```


## Acknowledgments ##
We thank Thomas Dent and Sumit Kumar for useful discussions and comments. We thank Stuart Anderson, Jonah Kannah, and Alan Weinstein for help accessing data from the Gravitational-Wave Open Science Center.  We acknowledge the Max Planck Gesellschaft for support and the Atlas cluster computing team at AEI Hannover. Computations were also supported by Syracuse University and NSF award OAC-1541396. DAB acknowledges NSF awards PHY-1707954, OAC-1443047, and OAC-1738962 for support. SR acknowledges NSF award PHY-1707954 and OAC-1443047 for support. RW acknowledges NSF award OAC-1823378 for support. 
This research has made use of data, software and/or web tools obtained from the Gravitational Wave Open Science Center (https://www.gw-openscience.org), a service of LIGO Laboratory, the LIGO Scientific Collaboration and the Virgo Collaboration. LIGO is funded by the U.S. National Science Foundation. Virgo is funded by the French Centre National de Recherche Scientifique (CNRS), the Italian Istituto Nazionale della Fisica Nucleare (INFN) and the Dutch Nikhef, with contributions by Polish and Hungarian institutes.
