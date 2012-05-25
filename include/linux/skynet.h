
#define RAMHACK64

// Overclock
#define SKYNET_AVP_FREQ 240000
#define SKYNET_VDE_FREQ SKYNET_AVP_FREQ
#define SKYNET_SYSTEM_FREQ SKYNET_AVP_FREQ
#define SKYNET_EMC_VOLT 1200
#define SKYNET_GPU_FREQ 400000
#define SKYNET_EMC2_FREQ ( SKYNET_VDE_FREQ * 5 / 2 )
#define SKYNET_DDR_FREQ ( SKYNET_EMC2_FREQ / 2 )

#define SKYNET_GPU_DIVIDER (7)

#define SKYNET_PLLA0 11289
#define SKYNET_PLLX0 1000000

#define SKYNET_BOOT_CLOCK 1100000

#define SKYNET_VOLT_1 775
#define SKYNET_VOLT_2 775
#define SKYNET_VOLT_3 800
#define SKYNET_VOLT_4 850
#define SKYNET_VOLT_5 950
#define SKYNET_VOLT_6 1075
#define SKYNET_VOLT_7 1175
#define SKYNET_VOLT_8 1275

#define SKYNET_CLOCK_1 216000
#define SKYNET_CLOCK_2 503000
#define SKYNET_CLOCK_3 655000
#define SKYNET_CLOCK_4 912000
#define SKYNET_CLOCK_5 1100000
#define SKYNET_CLOCK_6 1312000
#define SKYNET_CLOCK_7 1408000
#define SKYNET_CLOCK_8 1504000

//#define max_screenoff_frequency 503000

#define USE_FAKE_SHMOO

// /mm
#define vm_dirty_ratio_default 50
#define dirty_background_ratio_default 30
#define inactive_file_ratio_default 20
#define vfs_cache_pressure 100000
#define default_swappiness 99
#define VM_MAX_READAHEAD 32
#define VM_MIN_READAHEAD 16

// Scheduler
#define sysctl_sched_latency_default 6000000ULL
#define normalized_sysctl_sched_latency_default 6000000ULL
#define sysctl_sched_min_granularity_default 750000ULL
#define normalized_sysctl_sched_min_granularity_default 750000ULL
#define sched_nr_latency_default 8
#define sysctl_sched_wakeup_granularity_default 1000000UL
#define normalized_sysctl_sched_wakeup_granularity_default 1000000UL
#define CFS_BOOST
#define CFS_BOOST_NICE -17
