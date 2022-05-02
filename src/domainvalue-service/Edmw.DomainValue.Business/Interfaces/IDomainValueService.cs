using Edmw.DomainValue.Data.Dto;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Edmw.DomainValue.Business.Interfaces
{
    public interface IDomainValueService
    {
        Task<IEnumerable<DomainValueModel>> GetDomainValuesByDataClassNumber(int dataClsNum);
        Task<IEnumerable<DomainValueInfo>> GetAllDomainValues(int dataClsNum, string domainValue);
        Task<IEnumerable<CurrencyModel>> GetCurrencies();
    }
}
