/**********************************************************************

  2D3V PIC-MCC CODE '2D Arc-PIC'

  Copyright 2010-2015 CERN and Helsinki Institute of Physics.
  This software is distributed under the terms of the
  GNU General Public License version 3 (GPL Version 3),
  copied verbatim in the file LICENCE.md. In applying this
  license, CERN does not waive the privileges and immunities granted to it
  by virtue of its status as an Intergovernmental Organization
  or submit itself to any jurisdiction.

  Project website: http://arcpic.web.cern.ch/
  Developers: Helga Timko, Kyrre Sjobak

  efield.h:
  Header file for efield.cpp

***********************************************************************/

void electric_field_2D( double Phi[], double E_grid_r[], double E_grid_z[],
                        double E_ion_r[], double E_ion_z[],
                        int nr, int nz, int NR, int NZ );
