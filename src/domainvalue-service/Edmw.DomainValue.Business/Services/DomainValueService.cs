using AutoMapper;
using Edmw.Common.Utility;
using Edmw.DomainValue.Business.Interfaces;
using Edmw.DomainValue.Data.Dto;
using Edmw.DomainValue.Data.Entity;
using Edmw.DomainValue.Data.Interfaces;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq.Expressions;
using System.Threading.Tasks;

namespace Edmw.DomainValue.Business.Services
{
    public class DomainValueService : IDomainValueService
    {
        private readonly IDomainValueRepository _domainValueRepository;
        private readonly ILogger<DomainValueService> _logger;
        private readonly IMapper _mapper;

        public DomainValueService(IDomainValueRepository domainValueRepository
                                  , ILogger<DomainValueService> logger
                                  , IMapper mapper)
        {
            _domainValueRepository = domainValueRepository;
            _logger = logger;
            _mapper = mapper;
        }

        public async Task<IEnumerable<DomainValueModel>> GetDomainValuesByDataClassNumber(int dataClsNum)
        {
            _logger.LogDebug("GetDomainValuesByDataClassNumber execution started.");
            Expression<Func<DOMAIN_VALUE, bool>> dataClassNumberFilter = dmv => dataClsNum == default || dmv.DATA_CLS_NUM == dataClsNum;
            var domainValues = _mapper.Map<IEnumerable<DomainValueModel>>(await _domainValueRepository.GetDomainValues(dataClassNumberFilter));

            _logger.LogDebug("GetDomainValuesByDataClassNumber execution completed.");
            return domainValues;
        }

        public async Task<IEnumerable<CurrencyModel>> GetCurrencies()
        {
            _logger.LogDebug("GetCurrencies execution started.");
            var result = _mapper.Map<IEnumerable<DomainValueModel>, IEnumerable<CurrencyModel>>(await GetDomainValuesByDataClassNumber(2));
            _logger.LogDebug("GetCurrencies execution completed.");
            return result;
        }

        public async Task<IEnumerable<DomainValueInfo>> GetAllDomainValues(int dataClsNum, string domainValue)
        {
            _logger.LogDebug("GetAllDomainValues execution started.");
            Expression<Func<DOMAIN_VALUE, bool>> dataClassNumberFilter = dmv => dataClsNum == default || dmv.DATA_CLS_NUM == dataClsNum;
            Expression<Func<DOMAIN_VALUE, bool>> domainValueFilter = dmv => string.IsNullOrWhiteSpace(domainValue) || dmv.DMV_VALUE == domainValue;

            var domainFilter = dataClassNumberFilter.And(domainValueFilter);

            var domainValues = _mapper.Map<IEnumerable<DomainValueInfo>>(await _domainValueRepository.GetDomainValues(domainFilter));

            _logger.LogDebug("GetAllDomainValues execution completed.");
            return domainValues;
        }
    }
}
