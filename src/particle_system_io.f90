! This file is part of RMPCDMD
! Copyright (c) 2016-2017 Pierre de Buyl and contributors
! License: BSD 3-clause (see file LICENSE)

!> Facilities for particle data I/O
!!
!! The derived type thermo_t holds observables for temperature, center-of-mass velocity and
!! potential, kinetic and total energy.
!!
!! The derived type particle_system_io_t contains the typical particle data for a
!! simulation: position, velocity, etc.

module particle_system_io
  use hdf5
  use h5md_module
  use particle_system
  implicit none

  private

  public :: particle_system_io_t
  public :: particle_system_io_info_t
  public :: thermo_t

  type thermo_t
     integer :: n_buffer
     integer :: idx
     double precision, allocatable, dimension(:) :: temperature
     double precision, allocatable, dimension(:) :: potential_energy
     double precision, allocatable, dimension(:) :: kinetic_energy
     double precision, allocatable, dimension(:) :: internal_energy
     double precision, allocatable, dimension(:,:) :: center_of_mass_velocity
   contains
     procedure :: init => thermo_init
     procedure :: append => thermo_append
  end type thermo_t

  type particle_system_io_info_t
     integer :: mode
     integer :: step
     integer :: step_offset = -1
     double precision :: time
     double precision :: time_offset = -1
     logical :: store
  end type particle_system_io_info_t

  type particle_system_io_t
     integer :: Nmax
     integer :: error
     integer(HID_T) :: group
     type(h5md_element_t) :: box
     type(h5md_element_t) :: position
     type(h5md_element_t) :: image
     type(h5md_element_t) :: velocity
     type(h5md_element_t) :: force
     type(h5md_element_t) :: id
     type(h5md_element_t) :: species
     type(particle_system_io_info_t) :: position_info
     type(particle_system_io_info_t) :: image_info
     type(particle_system_io_info_t) :: velocity_info
     type(particle_system_io_info_t) :: force_info
     type(particle_system_io_info_t) :: id_info
     type(particle_system_io_info_t) :: species_info
   contains
     procedure :: init => ps_init
     procedure :: close => ps_close
  end type particle_system_io_t

contains

  subroutine ps_init(this, h5md_file, name, ps)
    class(particle_system_io_t), intent(inout) :: this
    type(h5md_file_t), intent(inout) :: h5md_file
    character(len=*), intent(in) :: name
    type(particle_system_t), intent(in) :: ps
    type(particle_system_io_info_t) :: info

    this% Nmax = ps% Nmax

    call h5gcreate_f(h5md_file% particles, name, this% group, this% error)

    if (this%position_info%store) then
       info = this%position_info
       if ( (info%step_offset < 0) .and. (info%time_offset > 0) .or. &
            (info%step_offset > 0) .and. (info%time_offset < 0) ) then
          stop 'use both or neither of step_offset and time_offset in ps_init position'
       end if
       if (iand(info%mode, H5MD_TIME) == H5MD_TIME) then
          call this%position%create_time(this% group, 'position', ps% pos, info%mode)
       else if (iand(info%mode, H5MD_LINEAR) == H5MD_LINEAR) then
          if (info%step_offset > 0) then
             call this%position%create_time(this% group, 'position', ps% pos, info%mode, info%step, &
                  info%time, step_offset=info%step_offset, time_offset=info%time_offset)
          else
             call this%position%create_time(this% group, 'position', ps% pos, info%mode, info%step, &
                  info%time)
          end if
       else if (iand(info%mode, H5MD_FIXED) == H5MD_FIXED) then
          call this%position%create_fixed(this% group, 'position', ps% pos)
       else
          stop 'unknown storage for position in particle_system_io init'
       end if
    end if

    if (this%velocity_info%store) then
       info = this%velocity_info
       if ( (info%step_offset < 0) .and. (info%time_offset > 0) .or. &
            (info%step_offset > 0) .and. (info%time_offset < 0) ) then
          stop 'use both or neither of step_offset and time_offset in ps_init velocity'
       end if
       if (iand(info%mode, H5MD_TIME) == H5MD_TIME) then
          call this%velocity%create_time(this% group, 'velocity', ps% vel, info%mode)
       else if (iand(info%mode, H5MD_LINEAR) == H5MD_LINEAR) then
          if (info%step_offset > 0) then
             call this%velocity%create_time(this% group, 'velocity', ps% vel, info%mode, info%step, &
                  info%time, step_offset=info%step_offset, time_offset=info%time_offset)
          else
             call this%velocity%create_time(this% group, 'velocity', ps% vel, info%mode, info%step, &
                  info%time)
          end if
       else if (iand(info%mode, H5MD_FIXED) == H5MD_FIXED) then
          call this%velocity%create_fixed(this% group, 'velocity', ps% vel)
       else
          stop 'unknown storage for velocity in particle_system_io init'
       end if
    end if

    if (this%force_info%store) then
       info = this%force_info
       if ( (info%step_offset < 0) .and. (info%time_offset > 0) .or. &
            (info%step_offset > 0) .and. (info%time_offset < 0) ) then
          stop 'use both or neither of step_offset and time_offset in ps_init velocity'
       end if

       if (iand(info%mode, H5MD_TIME) == H5MD_TIME) then
          call this%force%create_time(this% group, 'force', ps% vel, info%mode)
       else if (iand(info%mode, H5MD_LINEAR) == H5MD_LINEAR) then
          if (info%step_offset > 0) then
             call this%force%create_time(this% group, 'force', ps% pos, info%mode, info%step, &
                  info%time, step_offset=info%step_offset, time_offset=info%time_offset)
          else
             call this%force%create_time(this% group, 'force', ps% pos, info%mode, info%step, &
                  info%time)
          end if
       else if (iand(info%mode, H5MD_FIXED) == H5MD_FIXED) then
          call this%force%create_fixed(this% group, 'force', ps% vel)
       else
          stop 'unknown storage for force in particle_system_io init'
       end if
    end if

    if (this%image_info%store) then
       info = this%image_info
       if ( (info%step_offset < 0) .and. (info%time_offset > 0) .or. &
            (info%step_offset > 0) .and. (info%time_offset < 0) ) then
          stop 'use both or neither of step_offset and time_offset in ps_init image'
       end if

       if (iand(info%mode, H5MD_TIME) == H5MD_TIME) then
          call this%image%create_time(this% group, 'image', ps% image, info%mode)
       else if (iand(info%mode, H5MD_LINEAR) == H5MD_LINEAR) then
          if (info%step_offset > 0) then
             call this%image%create_time(this% group, 'image', ps% image, info%mode, info%step, &
                  info%time, step_offset=info%step_offset, time_offset=info%time_offset)
          else
             call this%image%create_time(this% group, 'image', ps% image, info%mode, info%step, &
                  info%time)
          end if
       else if (iand(info%mode, H5MD_FIXED) == H5MD_FIXED) then
          call this%image%create_fixed(this% group, 'image', ps% image)
       else
          stop 'unknown storage for image in particle_system_io init'
       end if
    end if

    if (this%id_info%store) then
       info = this%id_info
       if ( (info%step_offset < 0) .and. (info%time_offset > 0) .or. &
            (info%step_offset > 0) .and. (info%time_offset < 0) ) then
          stop 'use both or neither of step_offset and time_offset in ps_init id'
       end if

       if (iand(info%mode, H5MD_TIME) == H5MD_TIME) then
          call this%id%create_time(this% group, 'id', ps% id, info%mode)
       else if (iand(info%mode, H5MD_LINEAR) == H5MD_LINEAR) then
          if (info%step_offset > 0) then
             call this%id%create_time(this% group, 'id', ps% id, info%mode, info%step, &
                  info%time, step_offset=info%step_offset, time_offset=info%time_offset)
          else
             call this%id%create_time(this% group, 'id', ps% id, info%mode, info%step, &
                  info%time)
          end if
       else if (iand(info%mode, H5MD_FIXED) == H5MD_FIXED) then
          call this%id%create_fixed(this% group, 'id', ps% id)
       else
          stop 'unknown storage for id in particle_system_io init'
       end if
    end if

    if (this%species_info%store) then
       info = this%species_info
       if ( (info%step_offset < 0) .and. (info%time_offset > 0) .or. &
            (info%step_offset > 0) .and. (info%time_offset < 0) ) then
          stop 'use both or neither of step_offset and time_offset in ps_init species'
       end if

       if (iand(info%mode, H5MD_TIME) == H5MD_TIME) then
          call this%species%create_time(this% group, 'species', ps% species, info%mode)
       else if (iand(info%mode, H5MD_LINEAR) == H5MD_LINEAR) then
          if (info%step_offset > 0) then
             call this%species%create_time(this% group, 'species', ps% species, info%mode, info%step, &
                  info%time, step_offset=info%step_offset, time_offset=info%time_offset)
          else
             call this%species%create_time(this% group, 'species', ps% species, info%mode, info%step, &
                  info%time)
          end if
       else if (iand(info%mode, H5MD_FIXED) == H5MD_FIXED) then
          call this%species%create_fixed(this% group, 'species', ps% species)
       else
          stop 'unknown storage for species in particle_system_io init'
       end if
    end if

  end subroutine ps_init

  subroutine ps_close(this)
    class(particle_system_io_t), intent(inout) :: this

    call this% position% close()
    call h5gclose_f(this% group, this% error)

  end subroutine ps_close

  subroutine thermo_init(this, datafile, n_buffer, step, time, step_offset, time_offset)
    class(thermo_t), intent(out) :: this
    type(h5md_file_t), intent(inout) :: datafile
    integer, intent(in) :: n_buffer
    integer, intent(in) :: step
    double precision, intent(in) :: time
    integer, intent(in), optional :: step_offset
    double precision, intent(in), optional :: time_offset

    type(h5md_element_t) :: e
    double precision :: dummy, dummy_vec(3)
    integer :: mode

    if (n_buffer <= 0) error stop 'n_buffer non-positive in thermo_init'

    if ( (present(step_offset) .and. .not. present(time_offset)) .or. &
         (.not. present(step_offset) .and. present(time_offset)) ) &
         then
       stop 'in thermo_init, use both or neither of step_offset and time_offset'
    end if

    this% n_buffer = n_buffer
    this% idx = 0

    mode = ior(H5MD_LINEAR, H5MD_STORE_TIME)

    allocate(this% temperature(n_buffer))
    allocate(this% potential_energy(n_buffer))
    allocate(this% kinetic_energy(n_buffer))
    allocate(this% internal_energy(n_buffer))
    allocate(this% center_of_mass_velocity(3,n_buffer))

    if (present(step_offset) .and. present(time_offset)) then
       call e%create_time(datafile%observables, 'temperature', dummy, mode, step, time, &
            step_offset=step_offset, time_offset=time_offset)
       call e%close()
       call e%create_time(datafile%observables, 'potential_energy', dummy, mode, step, time, &
            step_offset=step_offset, time_offset=time_offset)
       call e%close()
       call e%create_time(datafile%observables, 'kinetic_energy', dummy, mode, step, time, &
            step_offset=step_offset, time_offset=time_offset)
       call e%close()
       call e%create_time(datafile%observables, 'internal_energy', dummy, mode, step, time, &
            step_offset=step_offset, time_offset=time_offset)
       call e%close()
       call e%create_time(datafile%observables, 'center_of_mass_velocity', dummy_vec, mode, step, time, &
            step_offset=step_offset, time_offset=time_offset)
       call e%close()
    else
       call e%create_time(datafile%observables, 'temperature', dummy, mode, step, time)
       call e%close()
       call e%create_time(datafile%observables, 'potential_energy', dummy, mode, step, time)
       call e%close()
       call e%create_time(datafile%observables, 'kinetic_energy', dummy, mode, step, time)
       call e%close()
       call e%create_time(datafile%observables, 'internal_energy', dummy, mode, step, time)
       call e%close()
       call e%create_time(datafile%observables, 'center_of_mass_velocity', dummy_vec, mode, step, time)
       call e%close()
    end if

  end subroutine thermo_init

  subroutine thermo_append(this, datafile, temperature, potential_energy, kinetic_energy, internal_energy, &
       center_of_mass_velocity, add, force)
    class(thermo_t), intent(inout) :: this
    type(h5md_file_t), intent(inout) :: datafile
    double precision, intent(in) :: temperature, potential_energy, kinetic_energy, internal_energy
    double precision, intent(in) :: center_of_mass_velocity(3)
    logical, intent(in), optional :: add, force

    integer :: i
    type(h5md_element_t) :: e
    logical :: do_add, do_append

    if (present(add)) then
       do_add = add
    else
       do_add = .true.
    end if

    if (do_add) then
       i = this%idx + 1
       this%idx = i

       this%temperature(i) = temperature
       this%potential_energy(i) = potential_energy
       this%kinetic_energy(i) = kinetic_energy
       this%internal_energy(i) = internal_energy
       this%center_of_mass_velocity(:,i) = center_of_mass_velocity
    end if

    do_append = (this%idx == this%n_buffer)

    if (present(force)) then
       if ((force) .and. (this%idx>0)) then
          do_append = .true.
       end if
    end if

    if (do_append) then
       call e%open_time(datafile%observables, 'temperature')
       call e%append_buffer(this%temperature, force_size=this%idx)
       call e%close()
       call e%open_time(datafile%observables, 'potential_energy')
       call e%append_buffer(this%potential_energy, force_size=this%idx)
       call e%close()
       call e%open_time(datafile%observables, 'kinetic_energy')
       call e%append_buffer(this%kinetic_energy, force_size=this%idx)
       call e%close()
       call e%open_time(datafile%observables, 'internal_energy')
       call e%append_buffer(this%internal_energy, force_size=this%idx)
       call e%close()
       call e%open_time(datafile%observables, 'center_of_mass_velocity')
       call e%append_buffer(this%center_of_mass_velocity, force_size=this%idx)
       call e%close()
       this%idx = 0
    end if

  end subroutine thermo_append

end module particle_system_io
