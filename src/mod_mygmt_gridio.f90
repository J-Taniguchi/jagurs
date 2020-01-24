#include "real.h"
module mod_mygmt_gridio
! === For negative max. height =================================================
use mod_params, only : missing_value
! ==============================================================================
implicit none
include 'netcdf.inc'

contains

! === For negative max. height =================================================
!  subroutine mygmt_grdio_d(z,x0,x1,y0,y1,dx,dy,zmin,zmax,nx,ny,filename)
   subroutine mygmt_grdio_d(z,x0,x1,y0,y1,dx,dy,zmin,zmax,nx,ny,filename, &
                            flag_missing_value)
! ==============================================================================
      real(kind=REAL_BYTE), dimension(nx,ny), intent(in) :: z
      real(kind=8), intent(in) :: x0, x1, y0, y1, dx, dy
      real(kind=REAL_BYTE), intent(in) :: zmin, zmax
      integer(kind=4), intent(in) :: nx, ny
      character(len=512), intent(in) :: filename
! === For negative max. height =================================================
      logical, optional, intent(in) :: flag_missing_value
! ==============================================================================

      integer(kind=4) :: ncid, side_dim, xysize_dim ! netCDF id dimensions ids
      integer(kind=4) :: xysize_len, side_len ! 2-dimension lengths
      integer(kind=4) :: x_range_id, y_range_id, z_range_id ! variable ids
      integer(kind=4) :: spacing_id, z_id, dimension_id
      integer(kind=4) :: x_range_dims(2), y_range_dims(2), z_range_dims(2)
      integer(kind=4) :: spacing_dims(2), dimension_dims(2), z_dims(2)
      real(kind=8) :: z_scale_factor(1), z_add_offset(1)
      integer(kind=4) :: z_node_offset(1)
      integer(kind=4) :: stat

      !** set these ***
      real(kind=8), allocatable, dimension(:) :: x_range, y_range, z_range, spacing
      integer(kind=4), allocatable, dimension(:) :: dimension
#ifdef REAL_DBLE
! === Write buffer must be 4 byte. =============================================
      real(kind=4), allocatable, dimension(:,:) :: z_tmp
! ==============================================================================
#endif

      xysize_len = nx*ny
      side_len = 2 ! 2 sides

      allocate(x_range(side_len))
      allocate(y_range(side_len))
      allocate(z_range(side_len))
      allocate(spacing(side_len))
      allocate(dimension(side_len))

      ! enter define mode
      stat = nf_create(filename, NF_CLOBBER, ncid)

      ! define 2 dimensions return dimension id's
      stat = nf_def_dim(ncid, 'side', side_len, side_dim)
      stat = nf_def_dim(ncid, 'xysize', xysize_len, xysize_dim)

      ! define variables
      x_range_dims(1) = side_dim
      y_range_dims(1) = side_dim
      z_range_dims(1) = side_dim
      spacing_dims(1) = side_dim
      dimension_dims(1) = side_dim
      z_dims(1) = xysize_dim

      stat = nf_def_var(ncid, 'x_range', NF_DOUBLE, 1, x_range_dims, x_range_id )
      stat = nf_def_var(ncid, 'y_range', NF_DOUBLE, 1, y_range_dims, y_range_id )
      stat = nf_def_var(ncid, 'z_range', NF_DOUBLE, 1, z_range_dims, z_range_id )
      stat = nf_def_var(ncid, 'spacing', NF_DOUBLE, 1, spacing_dims, spacing_id )
      stat = nf_def_var(ncid, 'dimension', NF_INT, 1, dimension_dims, dimension_id )
      stat = nf_def_var(ncid, 'z', NF_REAL, 1, z_dims, z_id)

      ! assign attributes
      stat = nf_put_att_text(ncid, x_range_id, 'units', 19, 'Longitude (Degrees)')
      stat = nf_put_att_text(ncid, y_range_id, 'units', 18, 'Latitude (Degrees)')
      stat = nf_put_att_text(ncid, z_range_id, 'units', 8, '(meters)')
      z_scale_factor(1) = 1
      stat = nf_put_att_double(ncid, z_id, 'scale_factor', NF_DOUBLE, 1, z_scale_factor)
      z_add_offset(1) = 0
      stat = nf_put_att_double(ncid, z_id, 'add_offset', NF_DOUBLE, 1, z_add_offset)
! === For negative max. height =================================================
      if(present(flag_missing_value) .and. flag_missing_value) then
         stat = nf_put_att_real(ncid, z_id, '_FillValue', NF_REAL, 1, &
                                real(missing_value))
      end if
! ==============================================================================
      ! Burbidge - changed this to normal    z_node_offset[0] = 1;
      z_node_offset(1) = 0 ! 1=pixel 0=node registration
      stat = nf_put_att_int(ncid, z_id, 'node_offset', NF_INT, 1, z_node_offset)
      stat = nf_put_att_text(ncid, NF_GLOBAL, 'title', 29, 'tsunami linear FD calculation')
      stat = nf_put_att_text(ncid, NF_GLOBAL, 'source', 17, 'ctsunami_rwg-v1.4')

      ! leave define mode
      stat = nf_enddef(ncid)

      x_range(1) = dble(x0)
      x_range(2) = dble(x1)
      y_range(1) = dble(y0)
      y_range(2) = dble(y1)
      z_range(1) = dble(zmin)
      z_range(2) = dble(zmax)
      spacing(1) = dble(dx)
      spacing(2) = dble(dy)
      dimension(1) = nx
      dimension(2) = ny

      ! store x y and z range spacing
      stat = nf_put_var_double(ncid, x_range_id, x_range)
      stat = nf_put_var_double(ncid, y_range_id, y_range)
      stat = nf_put_var_double(ncid, z_range_id, z_range)
      stat = nf_put_var_double(ncid, spacing_id, spacing)
      ! store dimension
      stat = nf_put_var_int(ncid, dimension_id, dimension)

      ! store z
#ifndef REAL_DBLE
      stat = nf_put_var_real(ncid, z_id, z)
#else
! === Write buffer must be 4 byte. =============================================
      allocate(z_tmp(nx,ny))
      z_tmp = z
      stat = nf_put_var_real(ncid, z_id, z_tmp)
      deallocate(z_tmp)
! ==============================================================================
#endif
      stat = nf_close(ncid)

      deallocate(x_range)
      deallocate(y_range)
      deallocate(z_range)
      deallocate(spacing)
      deallocate(dimension)

      return
   end subroutine mygmt_grdio_d

   subroutine read_gmt_grd_hdr(infilename, nx, ny, dx, dy, &
#ifndef PIXELIN
                               west, east, south, north, zmin, zmax)
#else
                               west, east, south, north, zmin, zmax, nxorg, nyorg)
      use mod_params, only : RUDEF, IUDEF
#endif
      character(len=256), intent(in) :: infilename
      integer(kind=4), intent(out) :: nx, ny
      real(kind=REAL_BYTE), intent(out) :: dx, dy, west, east, south, north, zmin, zmax

#ifndef PIXELIN
#ifndef NF
      !cf
      integer(kind=4) :: ncid, err
      integer(kind=4) :: side_id, xysize_id, side_len, xysize_len, side_dim, xysize_dim
      real(kind=8), allocatable, dimension(:) :: x_range, y_range, z_range, spacing
      integer(kind=4), allocatable, dimension(:) :: dimension
      integer(kind=4) :: x_range_id, y_range_id, z_range_id, spacing_id, dimension_id
#else
      !nf
      integer(kind=4) :: ncid, err
      character(len=256) :: tmp_char
      real(kind=8), allocatable, dimension(:) :: x_range, y_range, z_range, spacing
      real(kind=8), allocatable, dimension(:) :: x_tmp, y_tmp
      real(kind=8), allocatable, dimension(:,:) :: z_tmp
      integer(kind=4), allocatable, dimension(:) :: dimension
      integer(kind=4) :: x_var_id, y_var_id, z_var_id, x_dim_id, y_dim_id
#endif
#else
      integer(kind=4), intent(out) :: nxorg, nyorg
      character(len=256) :: descfile
      namelist /desc/ west, east, south, north, dx, dy, zmin, zmax, nx, ny
      real(kind=REAL_BYTE) :: westorg, eastorg, southorg, northorg
#endif

      !*** open the file and inquire about the dimensions ***
#ifndef PIXELIN
      err = nf_open(infilename, NF_NOWRITE, ncid)
      if(err /= NF_NOERR) then
         write(0,'(a,i0,a,a)') 'netcdf err=', err, ' nonexistent file=', trim(infilename)
         stop
      else if(err == NF_ENOTNC) then
         write(0,'(a,i0,a,a)') 'netcdf err=', err, ' non-netCDF file=', trim(infilename)
         stop
      end if
#ifndef NF
!cf
      err = nf_inq_dimid(ncid, 'side', side_id)
      err = nf_inq_dimid(ncid, 'xysize', xysize_id)

      !** get the dimensions ***
      err = nf_inq_dimlen(ncid, side_id, side_len)
      err = nf_inq_dimlen(ncid, xysize_id, xysize_len)
      side_dim = int(side_len)
      xysize_dim = int(xysize_len)

      !*** allocate space for variables ***
      allocate(x_range(side_dim))
      allocate(y_range(side_dim))
      allocate(z_range(side_dim))
      allocate(spacing(side_dim))
      allocate(dimension(side_dim))

      !*** get the variable id's - these variable names are common in GMT ***
      err = nf_inq_varid(ncid, 'x_range', x_range_id)
      err = nf_inq_varid(ncid, 'y_range', y_range_id)
      err = nf_inq_varid(ncid, 'z_range', z_range_id)
      err = nf_inq_varid(ncid, 'spacing', spacing_id)
      err = nf_inq_varid(ncid, 'dimension', dimension_id)

      !*** get the variables ***
      err = nf_get_var_double(ncid, x_range_id, x_range)
      err = nf_get_var_double(ncid, y_range_id, y_range)
      err = nf_get_var_double(ncid, z_range_id, z_range)
      err = nf_get_var_double(ncid, spacing_id, spacing)
      err = nf_get_var_int(ncid, dimension_id, dimension)
      err = nf_close(ncid)
#else
!nf
!平面2次元って決め打ちして良いですよね？
      allocate(x_range(2))
      allocate(y_range(2))
      allocate(z_range(2))
      allocate(spacing(2))
      allocate(dimension(2))
      err = nf_inq_dimid(ncid, 'x', x_dim_id)
      err = nf_inq_dimid(ncid, 'y', y_dim_id)
      err = nf_inq_dim(ncid, x_dim_id, tmp_char, dimension(1))
      err = nf_inq_dim(ncid, y_dim_id, tmp_char, dimension(2))
      allocate(x_tmp(dimension(1)))
      allocate(y_tmp(dimension(2)))
      allocate(z_tmp(dimension(2),dimension(1)))
      err =  nf_inq_varid(ncid, 'x', x_var_id)
      err =  nf_inq_varid(ncid, 'y', y_var_id)
      err =  nf_inq_varid(ncid, 'z', z_var_id)
      err = nf_get_var_double(ncid, x_var_id, x_tmp)
      err = nf_get_var_double(ncid, y_var_id, y_tmp)
      err = nf_get_var_double(ncid, z_var_id, z_tmp)
      x_range(1) = minval(x_tmp)
      x_range(2) = maxval(x_tmp)
      y_range(1) = minval(y_tmp)
      y_range(2) = maxval(y_tmp)
      z_range(1) = minval(z_tmp)
      z_range(2) = maxval(z_tmp)
      spacing(1) = (x_range(2) - x_range(1)) / (dimension(1) - 1)
      spacing(2) = (y_range(2) - y_range(1)) / (dimension(2) - 1)

      deallocate(x_tmp)
      deallocate(y_tmp)
      deallocate(z_tmp)

#endif
      !*** move values into return variables ***
#ifndef REAL_DBLE
      west  = x_range(1)
      east  = x_range(2)
      south = y_range(1)
      north = y_range(2)
      zmin  = z_range(1)
      zmax  = z_range(2)
      dx = spacing(1)
      dy = spacing(2)
      nx = dimension(1)
      ny = dimension(2)
#else
! === To avoid numerical error on MPI decomposition. ===========================
      west  = real(x_range(1))
      east  = real(x_range(2))
      south = real(y_range(1))
      north = real(y_range(2))
      zmin  = real(z_range(1))
      zmax  = real(z_range(2))
      dx = real(spacing(1))
      dy = real(spacing(2))
      nx = real(dimension(1))
      ny = real(dimension(2))
! ==============================================================================
#endif

      !*** free space ***/
      deallocate(x_range)
      deallocate(y_range)
      deallocate(z_range)
      deallocate(spacing)
      deallocate(dimension)
#else
      descfile = trim(infilename) // '.desc'
      open(1,file=trim(descfile),action='read',status='old',form='formatted',err=100)
      west = RUDEF; east = RUDEF; south = RUDEF; north = RUDEF
      dx   = RUDEF; dy   = RUDEF; nx    = IUDEF; ny    = IUDEF
      read(1,desc)
      if((west == RUDEF) .or. (east == RUDEF) .or. (south == RUDEF) .or. (north == RUDEF) .or. &
         (dx   == RUDEF) .or. (dy   == RUDEF) .or. (nx    == IUDEF) .or. (ny    == IUDEF)) goto 101
      nxorg = nx
      nyorg = ny
      nx = (nxorg-1)/3; nx = 3*nx+1
      ny = (nyorg-1)/3; ny = 3*ny+1
      westorg = west; eastorg = east; northorg = north; southorg = south
      west  = west  + 1.5d0*dx
      east  = east  - 1.5d0*dx
      north = north - 1.5d0*dy
      south = south + 1.5d0*dy
      close(1)
      write(6,'(a,a,a)') '[pixcel format] 1 grid on each edge is ignored on "', trim(infilename), """!"
      write(6,'(a,i6,a,i6)') '[pixcel format] Grid size is dealt as ', nx, ' x ', ny
      write(6,'(a,i6,a,i6,a)') '[pixcel format]    instead of it''s original gird size ', nxorg, ' x ', nyorg, '.'
      write(6,'(a,f0.3,a,f0.3,a)') '[pixcel format] West edge is changed from ', westorg, ' to ', west, '.'
      write(6,'(a,f0.3,a,f0.3,a)') '[pixcel format] East edge is changed from ', eastorg, ' to ', east, '.'
      write(6,'(a,f0.3,a,f0.3,a)') '[pixcel format] South edge is changed from ', southorg, ' to ', south, '.'
      write(6,'(a,f0.3,a,f0.3,a)') '[pixcel format] North edge is changed from ', northorg, ' to ', north, '.'
#ifdef PIXCELOUT
      write(6,'(a)') '[pixcel format] Note that the value on truncated area is zero!'
#endif
#endif

      return
#ifdef PIXELIN
 100  continue
      write(0,'(a,a,a)') 'Error! Descriptor file "', trim(descfile), '" does not exist!'
      stop
 101  continue
      write(0,'(a,a,a)') 'Error! Invalid description on descriptor file "', trim(descfile), '"!'
      stop
#endif
   end subroutine read_gmt_grd_hdr

   subroutine read_gmt_grd(infilename,z,nx,ny)
      character(len=256), intent(in) :: infilename
      real(kind=REAL_BYTE), dimension(nx,ny), intent(inout) :: z
!     real(kind=REAL_BYTE), intent(inout) :: z
      integer(kind=4), intent(in) :: nx, ny

      integer(kind=4) :: err, ncid, z_id
#ifdef REAL_DBLE
! === Read buffer must be 4 byte. ==============================================
      real(kind=4), allocatable, dimension(:,:) :: z_tmp
! ==============================================================================
#endif

      !*** open file again ***
      err = nf_open(infilename, NF_NOWRITE, ncid)
      if(err /= NF_NOERR) then
         write(0,'(a,i0,a,a)') 'netcdf err=', err, ' nonexistent file=', trim(infilename)
         stop
      else if(err == NF_ENOTNC) then
         write(0,'(a,i0,a,a)') 'netcdf err=', err, ' non-netCDF file=', trim(infilename)
         stop
      end if

      !*** inquire about z-data and read into float array
      !    assumes space is already allocated ***
      err = nf_inq_varid(ncid, 'z', z_id)
#ifndef REAL_DBLE
      err = nf_get_var_real(ncid, z_id, z)
#else
! === Read buffer must be 4 byte. ==============================================
      allocate(z_tmp(nx,ny))
      err = nf_get_var_real(ncid, z_id, z_tmp)
      z = z_tmp
      deallocate(z_tmp)
! ==============================================================================
#endif

      !*** close file and return pointer to array ***
      err = nf_close(ncid)

      return
   end subroutine read_gmt_grd

end module mod_mygmt_gridio
