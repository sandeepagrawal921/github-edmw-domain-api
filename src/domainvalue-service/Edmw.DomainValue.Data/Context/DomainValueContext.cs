using Edmw.Common.ConnectionHelper;
using Edmw.DomainValue.Data.Entity;
using Microsoft.EntityFrameworkCore;

namespace Edmw.DomainValue.Data.Context
{

    public partial class DomainValueContext : DbContext
    {
        private readonly IConnection _connection;
        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            if (!optionsBuilder.IsConfigured)
                optionsBuilder.UseSqlServer(_connection.Connection);
        }

        public DomainValueContext(DbContextOptions<DomainValueContext> options, IConnection connection) : base(options)
        {
            _connection = connection;
        }

        public virtual DbSet<DOMAIN_VALUE> DOMAIN_VALUE { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<DOMAIN_VALUE>(entity =>
            {
                entity.HasKey(e => e.DMV_VAL_NUM)
                    .IsClustered(false);

                entity.ToTable("DOMAIN_VALUE");

                entity.HasIndex(e => new { e.DATA_CLS_NUM, e.DMV_VALUE }, "DMVL_DClsNumDmvVal_bnu")
                    .IsUnique();

                entity.HasIndex(e => e.DATA_CLS_NUM, "DMVL_DataClsNum_fnn")
                    .IsClustered();

                entity.Property(e => e.DMV1_IND).HasMaxLength(3);

                entity.Property(e => e.DMV2_IND).HasMaxLength(3);

                entity.Property(e => e.DMV3_IND).HasMaxLength(3);

                entity.Property(e => e.DMV4_IND).HasMaxLength(3);

                entity.Property(e => e.DMV5_IND).HasMaxLength(3);

                entity.Property(e => e.DMV_DESC).HasMaxLength(255);

                entity.Property(e => e.DMV_NME).HasMaxLength(40);

                entity.Property(e => e.DMV_VALUE).HasMaxLength(40);

                entity.Property(e => e.FLD_DATA_CL_ID).HasMaxLength(10);

                entity.Property(e => e.FLD_ID).HasMaxLength(10);

                entity.Property(e => e.INTRL_DMN_VAL_ID).HasMaxLength(10);

                entity.Property(e => e.LST_CHG_TMS).HasColumnType("datetime");

                entity.Property(e => e.LST_CHG_USR_ID)
                    .IsRequired()
                    .HasMaxLength(8);

                entity.Property(e => e.NLS_CDE).HasMaxLength(8);

                entity.Property(e => e.ORG_ID).HasMaxLength(4);
            });

            OnModelCreatingPartial(modelBuilder);
        }

        partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
    }
}
