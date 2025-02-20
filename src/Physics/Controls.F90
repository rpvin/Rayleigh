!
!  Copyright (C) 2018 by the authors of the RAYLEIGH code.
!
!  This file is part of RAYLEIGH.
!
!  RAYLEIGH is free software; you can redistribute it and/or modify
!  it under the terms of the GNU General Public License as published by
!  the Free Software Foundation; either version 3, or (at your option)
!  any later version.
!
!  RAYLEIGH is distributed in the hope that it will be useful,
!  but WITHOUT ANY WARRANTY; without even the implied warranty of
!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!  GNU General Public License for more details.
!
!  You should have received a copy of the GNU General Public License
!  along with RAYLEIGH; see the file LICENSE.  If not see
!  <http://www.gnu.org/licenses/>.
!

Module Controls
    ! Things that control how the simulation runs
    Use BufferedOutput
    Implicit None

    !////////////////////////////////////////////////////////////////////////////////
    ! Multiple run controls,  These are not set in a namelist, but are used through command line options.
    Character*120, Allocatable :: rundirs(:)
    Logical :: multi_run_mode = .false.
    Integer :: nruns = 0 ! only set to non-zero value if multi_run_mode is True
    Integer, Allocatable :: run_cpus(:)
    Character*120 :: my_path = ''
    Integer :: my_sim_id = 1  ! Simulation ID (needed for main_input broadcast)

    !////////////////////////////////////////////////////////////////////////////////
    ! Numerical Controls
    ! Flats that control details of the parallelization/data layout and
    ! how the equations are solved (not what equations are solved).
    Logical :: chebyshev = .true.           ! Set to false to use finite-differences (chebyshev polynomials are used by default)
    Logical :: bandsolve = .false.          ! Set to true to use band solves with the finite-differences
    Logical :: static_transpose = .false.   ! When true, transpose buffers for sending/receiving are never de-allocated for spherical buffer objects
    Logical :: static_config = .false.      ! When true, configuration buffers (p3a, s1b, etc.) ar enever de-allocated for spherical buffer objects
    Logical :: use_parity = .true.          ! Possibly defunct - should always be true
    Logical :: deriv_cluge = .true.         ! Use modified 2nd derivative in radius for finite-differences (leave true for stability...for now)
    Logical :: pad_alltoall = .false.       ! Normally all-to-allv is used.  Standard alltoall with zero padded buffers can be used when this flag is on.
    Logical :: sparsesolve = .false.

    Logical :: m_balance_contiguous = .false. ! Use alternative ordering of m-values such that access of successive values is contiguous
                                              ! There are currently only 2 versions, T/F is mapped to integer 1/0. If more versions
                                              ! are added in the future, the Logical type and variable name should change

    Namelist /Numerical_Controls_Namelist/ chebyshev, bandsolve, static_transpose, static_config, &
            & use_parity, deriv_cluge, pad_alltoall, sparsesolve, m_balance_contiguous

    !////////////////////////////////////////////////////////////////////////////////
    ! Physical Controls
    ! Flags that control various fundamental aspects of the physics employed
    Logical :: magnetism = .false.          ! Turn magnetism on or off (default is off)
    Logical :: nonlinear = .true.           ! Nonlinear terms can be turned off (calculated but zeroed out - for debugging)
    Logical :: momentum_advection = .true.  ! u dot grad u is not calculated (mostly useful for debugging)
    Logical :: inertia = .true.             ! If false, Du/Dt is set to zero (useful for mantle convection problems)
    Logical :: Rotation = .false.           ! Rotate or not
    Logical :: lorentz_forces = .true.      ! Turn Lorentz forces on or off (default is on - as long as magnetism is on)
    Logical :: viscous_heating = .true.     ! Turns viscous heating on/off
    Logical :: ohmic_heating = .true.
    Logical :: advect_reference_state = .true.  ! Set to true to advect the reference state temperature or entropy
                                                ! This has no effect for adiabatic reference states.

    ! --- This flag determines if the code is run in benchmark mode
    !     0 (default) is no benchmarking.  1-5 are various accuracy benchmarks (see documentation)
    Integer :: benchmark_mode = 0
    Integer :: benchmark_integration_interval = -1 ! manual override of integration_interval
    Integer :: benchmark_report_interval = -1      ! and report interval in Benchmarking.F90 (for debugging)

    Namelist /Physical_Controls_Namelist/ magnetism, nonlinear, rotation, lorentz_forces, &
                & viscous_heating, ohmic_heating, advect_reference_state, benchmark_mode, &
                & benchmark_integration_interval, benchmark_report_interval, &
                & momentum_advection, inertia

    !///////////////////////////////////////////////////////////////////////////
    !   Temporal Controls
    !   Flags that control details of the time-stepping (some relate to the numerics, but we keep the time-related things together).
    Real*8  :: alpha_implicit = 0.5d0       ! Crank Nicolson Implict/Explicit weighting factor (1.0 is fully implicit)
    Integer :: max_iterations = 1000000     ! The maximum number of iterations to be run in a given session
    Real*8  :: max_time_minutes = 1d8       ! Maximum walltime to run the code (this should be ample...)
    Real*8  :: max_simulated_time = 1d20   ! Maximum simulation time to evolve the model for

    Logical :: save_last_timestep = .true.
    Logical :: save_on_sigterm = .false.       ! Rayleigh will attempt to checkpoint and exit upon termination request
    Integer :: check_frequency = -1            ! Number of iterations between checkpoint dumps
    Integer :: checkpoint_interval = 1000000   ! Same as check_frequency (check_frequency will be deprecated soon)
    Integer :: quicksave_interval =  -1        ! Number of iterations between quicksave dumps
    Integer :: num_quicksaves = 3              ! Number of quick-save checkpoints to write before rolling back to #1
    Real*8  :: quicksave_minutes = -1.0d0      ! Time in minutes between quick saves (overrides quicksave interval)

    Real*8  :: cflmax = 0.6d0, cflmin = 0.4d0  ! Limits for the cfl condition
    Real*8  :: max_time_step = 1.0d0           ! Maximum timestep to take, whatever CFL says (should always specify this in main_input file)
    Real*8  :: min_time_step = 1.0d-13
    Integer :: diagnostic_reboot_interval = 10000000
    Integer :: new_iteration = 0
    Namelist /Temporal_Controls_Namelist/ alpha_implicit, max_iterations, check_frequency, &
                & cflmax, cflmin, max_time_step, diagnostic_reboot_interval, min_time_step, &
                & num_quicksaves, quicksave_interval, checkpoint_interval, quicksave_minutes, &
                & max_time_minutes, save_last_timestep, new_iteration, save_on_sigterm, &
                & max_simulated_time



    !///////////////////////////////////////////////////////////////////////////
    ! I/O Controls
    ! What is normally sent to standard out can, if desired, be sent to a file instead
    Integer :: stdout_flush_interval = 50  ! Lines stored before stdout buffer is flushed to stdout_unit
    Integer :: terminate_check_interval = 50  ! check for presence of terminate_file every n-th time step
    Integer :: statusline_interval = 1  ! output status information only every n-th time step
    Integer :: outputs_per_row = 1    ! Number of MPI ranks, per process row, that participate in parallel writes.
    Character*120 :: stdout_file = 'nofile'
    Character*120 :: jobinfo_file = 'jobinfo.txt'
    Character*120 :: terminate_file = 'terminate'
    Integer :: integer_output_digits = 8  ! Number of digits for integer-filename output (default 8; e.g., 00010000)
    Integer :: integer_input_digits  = 8  ! Number of digits for integer-filename input
    Integer :: decimal_places = 3         ! Number of digits after decimal for scientific notation output

    Namelist /IO_Controls_Namelist/ stdout_flush_interval,terminate_check_interval,statusline_interval, &
       stdout_file,jobinfo_file,terminate_file, integer_output_digits, integer_input_digits, &
       decimal_places, outputs_per_row


    !//////////////////////////////////////////////////////////////////////////////////
    !Variables that are controlled by those which appear in a namelist

    !~~These format codes controlled by n_[input/output]_digits
    Character*8 :: int_in_fmt = '(i8.8)'        ! Format code for positive integer input
    Character*8 :: int_out_fmt='(i8.8)'         ! Format code for positive integer output
    Character*8 :: int_minus_in_fmt = '(i9.8)'  ! Format code for negative integer input
    Character*8 :: int_minus_out_fmt='(i9.8)'   ! Format code for negative integer output
    Character*9 :: sci_note_fmt ='(ES10.3)'     ! Format code for scientific-notation output

    !///////////////////////////////////////////////////////////////////////////////////
    ! This array may be used for various purposes related to passing messages to the
    ! full pool of processes
    Real*8, Allocatable :: global_msgs(:)
    Real*8 :: kill_signal = 0.0d0  ! Signal will be passed in Real*8 buffer, but should be integer-like
    Integer :: nglobal_msgs = 5  ! timestep, elapsed since checkpoint, kill_signal/global message, simulation time, terminate file found

    Logical :: full_restart = .false.  ! Set to true if a full-restart is initiated from the command line

Contains
    Subroutine Initialize_Controls()
        Implicit None
        character*120 :: ofilename
        chebyshev = .true.   ! finite-difference is not currently supported
        Allocate(global_msgs(1:nglobal_msgs))
        global_msgs = 0.0d0

        !Set default for diagnostic_reboot_interval (if necessary)
        If (diagnostic_reboot_interval .le. 0) Then
            diagnostic_reboot_interval = checkpoint_interval
        Endif

        !Initialize the stdout buffer -- by default, write to unit 6 with frequency of 1
        Select Case(stdout_file)
            Case('stdout')    ! Standard out, but flush with user-defined frequency
                Call stdout%init(6,line_count = stdout_flush_interval)
            Case('nofile')
                Call stdout%init(6) ! Standard out, with effectively no buffering (line_count = 1)
            Case Default
                ! All stdout written to file, flushed at user-defined flush interval
                ofilename = Trim(my_path)//Trim(stdout_file)
                Call stdout%init(116,line_count = stdout_flush_interval,filename=ofilename)
        End Select
        If (.not. inertia) Then
            Write(6,*)"Setting momentum_advection to False"
            momentum_advection = .false.
        Endif

        Call Initialize_IO_Format_Codes()

    End Subroutine Initialize_Controls

    Subroutine Initialize_IO_Format_Codes
        Implicit None
        Character*2 :: dig_str, dig_str2

        !//////////////////////////////////////////////////////
        ! Set format code for integer output file names
        Write(dig_str,'(i2)')integer_output_digits
        int_out_fmt = '(i'//trim(dig_str)//'.'//trim(dig_str)//')'

        ! (Same, but for negative numbers)
        Write(dig_str2,'(i2)')integer_output_digits+1
        int_minus_out_fmt = '(i'//trim(dig_str2)//'.'//trim(dig_str)//')'

        !///////////////////////////////////////////////
        ! Next, set the input file format codes
        Write(dig_str,'(i2)')integer_input_digits
        int_in_fmt = '(i'//trim(dig_str)//'.'//trim(dig_str)//')'

        Write(dig_str2,'(i2)')integer_input_digits+1
        int_minus_in_fmt = '(i'//trim(dig_str2)//'.'//trim(dig_str)//')'

        !///////////////////////////////////////////////
        ! Set the format code for scientific notation
        Write(dig_str ,'(i2)')decimal_places+7 
        Write(dig_str2,'(i2)')decimal_places
        sci_note_fmt = '(ES'//trim(dig_str)//'.'//trim(dig_str2)//')'

    End Subroutine Initialize_IO_Format_Codes

    Subroutine Restore_Physics_Defaults()
        Implicit None
        magnetism = .false.
        nonlinear = .true.
        Rotation = .false.
        lorentz_forces = .true.
        viscous_heating = .true.
        ohmic_heating = .true.
        advect_reference_state = .true.
        benchmark_mode = 0
        benchmark_integration_interval = -1
        benchmark_report_interval = -1
    End Subroutine Restore_Physics_Defaults

    Subroutine Restore_Numerical_Defaults
        Implicit None
        chebyshev = .false.
        bandsolve = .false.
        static_transpose = .false.
        static_config = .false.
        use_parity = .true.
        deriv_cluge = .true.
        pad_alltoall = .false.
        m_balance_contiguous = .false.
    End Subroutine Restore_Numerical_Defaults

    Subroutine Restore_Temporal_Defaults
        Implicit None
        alpha_implicit = 0.51d0
        max_iterations = 1000000
        max_time_minutes = 1d8

        check_frequency = -1
        checkpoint_interval = 1000000
        quicksave_interval =  -1
        num_quicksaves = 3
        quicksave_minutes = -1.0d0

        cflmax = 0.4d0
        cflmin = 0.6d0
        max_time_step = 1.0d0
        min_time_step = 1.0d-13
        diagnostic_reboot_interval = -1
    End Subroutine Restore_Temporal_Defaults


    Subroutine Restore_IO_Defaults
        Implicit None
        stdout_flush_interval = 50
        stdout_file = 'nofile'
        terminate_check_interval = 50
        terminate_file = 'terminate'
        statusline_interval = 1
    End Subroutine Restore_IO_Defaults
End Module Controls
