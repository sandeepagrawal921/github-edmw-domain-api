using Common.Logger;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Hosting;

namespace Edmw.DomainValue.Api
{
    public class Program
    {
        public static void Main(string[] args)
        {
            CreateHostBuilder().Build().Run();
        }

        public static IHostBuilder CreateHostBuilder() =>
            Host.CreateDefaultBuilder()
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.UseStartup<Startup>();
                }).UseLogging("Domain Value Microservice");
    }
}
