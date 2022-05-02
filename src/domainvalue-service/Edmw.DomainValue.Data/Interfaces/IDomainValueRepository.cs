using Edmw.DomainValue.Data.Entity;
using System;
using System.Collections.Generic;
using System.Linq.Expressions;
using System.Threading.Tasks;

namespace Edmw.DomainValue.Data.Interfaces
{
    public interface IDomainValueRepository
    {
        Task<IEnumerable<DOMAIN_VALUE>> GetDomainValues(Expression<Func<DOMAIN_VALUE, bool>> whereClause);
    }
}
