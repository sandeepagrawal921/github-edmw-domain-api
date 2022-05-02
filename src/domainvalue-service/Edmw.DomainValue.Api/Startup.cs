using Common.Auth;
using Common.Health;
using Common.Logger;
using Common.Mvc;
using Common.Swagger;
using Edmw.Common.ConnectionHelper;
using Edmw.DomainValue.Business.AutoMapper;
using Edmw.DomainValue.Business.Interfaces;
using Edmw.DomainValue.Business.Services;
using Edmw.DomainValue.Data.Context;
using Edmw.DomainValue.Data.Interfaces;
using Edmw.DomainValue.Data.Repositories;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Edmw.DomainValue.Api
{
    public class Startup
    {
        private const string SERVICENAME = "domainvalue-service";
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddControllers().AddNewtonsoftJson(
                  options =>
                  {
                      options.SerializerSettings.FloatParseHandling = Newtonsoft.Json.FloatParseHandling.Decimal;
                  }).AddXmlSerializerFormatters().AddXmlDataContractSerializerFormatters();

            services.AddCustomMvc();

            services.AddDefaultCustomApiVersioning();

            // Register health check services
            services.AddHealthChecks();

            // Enable Consul
            //services.AddConsul(Configuration);
            services.AddSwagger()
                    .AddClientTokenManager(Configuration);

            services.AddTransient<IDomainValueService, DomainValueService>();
            services.AddTransient<IDomainValueRepository, DomainValueRepository>();

            services.AddSingleton<IHttpContextAccessor, HttpContextAccessor>();
            services.AddScoped<IConnection, ConnectionString>();
            services.AddDbContext<DomainValueContext>(ServiceLifetime.Scoped);

            services.AddResponseCaching();
            services.AddAutoMapper(typeof(DomainValueProfile));

            services.AddIdentityServerBearerAuthentication(Configuration);
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            var appsettings = Configuration.GetSection("AppSettings");
            app.UseErrorHandler();

            app.UseSwaggerWithUI(appsettings["swaggerClientId"], appsettings["swaggerClientName"]);

            app.UseSerilogHttpSink();

            app.UseHsts();
            app.UseHttpsRedirection();
            app.UseResponseCaching();

            app.UseRouting();

            app.UseAuthentication();
            app.UseAuthorization();
            app.UseHealthCheckWriter(SERVICENAME);

            app.UseEndpoints(endPoints =>
            {
                endPoints.MapControllers();
            });
        }
    }

    public static class ServiceExtension
    {
        public static void AddDefaultCustomApiVersioning(this IServiceCollection services)
        {
            services.AddApiVersioning().AddVersionedApiExplorer(options =>
            {
                // add the versioned api explorer, which also adds IApiVersionDescriptionProvider service
                // note: the specified format code will format the version as "'v'major[.minor][-status]"
                options.GroupNameFormat = "'v'VVV";

                // note: this option is only necessary when versioning by url segment. the SubstitutionFormat
                // can also be used to control the format of the API version in route templates
                options.SubstituteApiVersionInUrl = true;
            });
        }
    }
}
