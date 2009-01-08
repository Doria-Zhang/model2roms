       
Module interpolation
        implicit none
                
        contains
  
            subroutine doVertInter(dat,bathymetry,outdat,zr,zs,Nroms,Nsoda,II,JJ)
            
            ! ----------------------------------
            ! Program : DOVERTINTER
            !
            ! This routine interpolates from z-levels to sigma levels using linear interpolation.
            !
            ! The index values in python goes from 0 toN while in Fortran they run from 1 to N+1. This is important to
            ! remember if one wants to compare input index wtih output index in fortran and python.
            !
            ! This routine assumes that the two depth matrixes zr (ROMS) and zs (SODA) are arranged from shallowest
            ! (index=1) to deepest (index=N+1). The depth matrizes must also be begative (if positive, reverse all
            ! comparison signs (e.g. LT, GT) in the program or multiply with minus 1). The input data are arranged with
            ! deepest values at highest index (N+1 e.g. dat(N+1)==bottom, dat(1)==surface). This is done so because
            ! it is the way SODA data are organized (bottom at highest index). However, ROMS output files are organized vice versa, so
            ! to accomodate that the output values are stored according to the ROMS structure. Highest index (N+1) equals surface,
            ! while lowest index equals bottom (index=1)(see how outdat(Nroms-kc+1,jc,ic) is used opposite of the loop over kc).
            !
            ! Trond Kristiansen, December 2008, and January 2009
            ! Rutgers University, NJ.
            ! -------------------------------------------------------------------------------------------------------
            !
            ! USAGE: Compile this routine using Intel Fortran compiler and create
            ! a python module using the command:
            ! f2py --verbose --fcompiler=intel -c -m vertInterp verticalInterp.f90
            !
            ! The resulting module is imported to python using:
            ! import vertInterp as interp2D
            ! To call the function from python use:
            ! interp2D.doHorInterpolation(dat,bathymetry,outdat,zr,zs,Nroms,Nsoda,II,JJ)
            !
            ! where: dat is the data such as temperature (3D structure (z,y,x))
            !        bathymetry is the 2D bottom matrix from the output grid (in ROMS this is usually 'h')
            !        outdat is a 3D output array with the correct size (Nroms,JJ,II)
            !        zr is the depth matrix for the output grid (Nroms,JJ,II)
            !        zs is the 1D SODA depth-matrix (e.g. zs=[5,10,20,30])
            !        Nroms is the total depth levels in output grid
            !        JJ is the total grid points in eta direction
            !        II is the total grid points in xi direction
            ! -------------------------------------------------------------------------------------------------------
            
            double precision rz2, rz1
            integer II, JJ, ic, jc, kc, kT, Nsoda, Nroms
            double precision, dimension(Nsoda,JJ,II) :: dat
            double precision, dimension(JJ,II) :: bathymetry
            double precision, dimension(Nroms,JJ,II) :: zr, outdat
            double precision, dimension(Nsoda) ::  zs
       
!f2py intent(in) dat, bathymetry, zr, zs, Nroms, Nsoda, JJ, II
!f2py intent(in,out) outdat
!f2py intent(hide) ic,jc,kc,kT,rz1,rz2
            
            do jc=1,JJ
              do ic=1,II
                  do kc=1,Nroms
                      
                      ! CASE 1: ROMS deeper than SODA
                      IF (zr(kc,jc,ic) .LT. zs(Nsoda)) THEN
                          outdat(Nroms-kc+1,jc,ic)=dat(Nsoda,jc,ic)
                          !print*,zr(kc,jc,ic),zs(Nsoda),dat(Nsoda,jc,ic),jc,ic,'case 1'
                          
                      ! CASE 2: ROMS shallower than SODA
                      ELSE IF (zr(kc,jc,ic) .GT. zs(1)) THEN
                          outdat(Nroms-kc+1,jc,ic)=dat(1,jc,ic)
                       
                          !print*,zr(kc,jc,ic),zs(1),dat(1,jc,ic),jc,ic,'case 2'
                     
                      ! Do linear interpolation
                      ELSE
                          DO kT=1,Nsoda
                              ! CASE 3: ROMS deeper than SODA for one layer, but shallower than next SODA layer (bottom in between)
                              ! Deeper than some SODA depth layer, but shallower than next layer which is below bottom
                              IF (zr(kc,jc,ic) .LE. zs(kT) .AND.               &
                                -(bathymetry(jc,ic)) .GT. zs(kT+1)) THEN
                                outdat(Nroms-kc+1,jc,ic)=dat(kT,jc,ic)
                                !print*,zr(kc,jc,ic),zs(kT),dat(kT,jc,ic),jc,ic,'case 3'
                                
                              ! CASE 4: ROMS layer in between two SODA layers
                              ELSE IF ( (zr(kc,jc,ic) .LT. zs(kT)) .AND.       &
                              (zr(kc,jc,ic) .GE. zs(kT+1)) .AND.               &
                              (-bathymetry(jc,ic) .LT. zs(kT+1)) ) THEN
                              
                                 rz2 = abs((zr(kc,jc,ic)-zs(kT+1))/            &
                                 (abs(zs(kT+1))-abs(zs(kT))))
                                 
                                 rz1 = 1.0-rz2
        
                                 outdat(Nroms-kc+1,jc,ic) = (rz1*dat(kT+1,jc,ic) &
                                 + rz2*dat(kT,jc,ic))
                                
                                 exit 
                              end if
                          end do
                      end if
           
                  end do
              end do
            end do
        
        
      end subroutine doVertInter
    end module interpolation
    
