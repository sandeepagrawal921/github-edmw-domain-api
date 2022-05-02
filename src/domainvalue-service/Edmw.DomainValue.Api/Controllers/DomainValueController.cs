using Edmw.DomainValue.Business.Interfaces;
using Edmw.DomainValue.Data.Dto;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System.Net;
using System.Threading.Tasks;

namespace EDMW.DomainValue.RestAPI.Controllers
{
    [ApiVersion("17.1")]
    [Route("api/v{version:apiVersion}/DomainValue")]
    [ApiController]
    public class DomainValueController : ControllerBase
    {
        private readonly IDomainValueService _domainValueService;
        private readonly ILogger<DomainValueController> _logger;

        public DomainValueController(IDomainValueService domainValueService, ILogger<DomainValueController> logger)
        {
            _domainValueService = domainValueService;
            _logger = logger;
        }

        [HttpGet("currencies")]
        [ProducesResponseType(typeof(CurrencyModel), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> GetAllCurrencies()
        {
            _logger.LogDebug("Executing GetAllCurrencies");

            var result = await _domainValueService.GetCurrencies();

            if (result == null)
            {
                _logger.LogInformation($"NoContent. Status Code-{HttpStatusCode.NoContent}");
                return NoContent();
            }

            _logger.LogDebug("Executed GetAllCurrencies");

            return Ok(result);
        }

        [HttpGet("{dataclassnum}")]
        [ProducesResponseType(typeof(DomainValueModel), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> GetDomainValuesByDataClassNumber(int dataClassNum)
        {
            _logger.LogDebug("Executing GetDomainValuesByDataClassNumber");
            _logger.LogDebug("Input parameters - dataClassNum - {@dataClassNum}", dataClassNum);
            var data = await _domainValueService.GetDomainValuesByDataClassNumber(dataClassNum);
            if (data == null)
            {
                _logger.LogInformation($"NoContent. Status Code-{HttpStatusCode.NoContent}");
                return NoContent();
            }

            _logger.LogDebug("Executed GetDomainValuesByDataClassNumber");

            return Ok(data);
        }

        [HttpGet]
        [ProducesResponseType(typeof(DomainValueInfo), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> GetAllDomainValues([FromQuery] int dataClassNum = 0, [FromQuery] string domainValue = "")
        {
            _logger.LogDebug("Executing GetAllDomainValues");
            _logger.LogDebug("Input parameters - dataClassNum - {@dataClassNum}, domainValue - {@domainValue} ", dataClassNum, domainValue);
            var result = await _domainValueService.GetAllDomainValues(dataClassNum, domainValue);
            if (result == null)
            {
                _logger.LogInformation($"NoContent. Status Code-{HttpStatusCode.NoContent}");
                return NoContent();
            }

            _logger.LogDebug("Executed GetAllDomainValues");
            return Ok(result);
        }
    }
}
