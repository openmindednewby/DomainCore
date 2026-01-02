# DomainCore

[![NuGet](https://img.shields.io/nuget/v/DomainCore.svg)](https://www.nuget.org/packages/DomainCore)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Domain primitives, base entities, aggregate roots, and domain events for building Domain-Driven Design applications with .NET.

## 📦 Installation

```bash
dotnet add package DomainCore
```

## 🚀 Features

- **Base Entities**: `BaseEntity` with `Id`, `ExternalId`, and audit fields
- **Tenant Entities**: `BaseTenantEntity` for multi-tenant applications
- **Aggregate Roots**: `IAggregateRoot` marker interface
- **Domain Events**: `DomainEventBase` and `HasDomainEventsBase` for event-driven design
- **Value Objects**: Base classes for implementing value objects
- **Audit Fields**: Built-in `CreatedAt`, `CreatedBy`, `UpdatedAt`, `UpdatedBy` tracking

## 📖 Usage

### Basic Entity

```csharp
using DomainCore.Entities;

public class Product : BaseEntity
{
    public string Name { get; set; }
    public decimal Price { get; set; }

    public Product(string name, decimal price, Guid userId)
    {
        Name = name;
        Price = price;
        SetUser(userId);
    }
}
```

### Multi-Tenant Entity

```csharp
using DomainCore.Entities;

public class Order : BaseTenantEntity
{
    public Guid ProductId { get; set; }
    public int Quantity { get; set; }
    public decimal TotalPrice { get; set; }

    public Order(Guid productId, int quantity, decimal totalPrice, Guid tenantId, Guid userId)
    {
        ProductId = productId;
        Quantity = quantity;
        TotalPrice = totalPrice;
        SetTenant(tenantId);
        SetUser(userId);
    }
}
```

### Domain Events

```csharp
using DomainCore.Events;

public class OrderPlacedEvent : DomainEventBase
{
    public Guid OrderId { get; }
    public decimal TotalAmount { get; }

    public OrderPlacedEvent(Guid orderId, decimal totalAmount)
    {
        OrderId = orderId;
        TotalAmount = totalAmount;
    }
}

public class Order : BaseTenantEntity
{
    public void Place()
    {
        // Business logic...
        IsPlaced = true;
        UpdateTimestamp();

        // Raise domain event
        RegisterDomainEvent(new OrderPlacedEvent(ExternalId, TotalPrice));
    }
}
```

## 🏗️ Base Classes

### BaseEntity

Provides common entity properties:
- `Guid Id` - Internal database ID
- `Guid ExternalId` - Public-facing UUID
- `DateTime CreatedAt` - Creation timestamp
- `Guid? CreatedBy` - User who created the entity
- `DateTime? UpdatedAt` - Last update timestamp
- `Guid? UpdatedBy` - User who last updated the entity

### BaseTenantEntity

Extends `BaseEntity` with multi-tenancy:
- `Guid TenantId` - Tenant identifier for data isolation
- `void SetTenant(Guid tenantId)` - Set the tenant ID

### HasDomainEventsBase

For entities that raise domain events:
- `List<DomainEventBase> DomainEvents` - Collection of events
- `void RegisterDomainEvent(DomainEventBase domainEvent)` - Add event
- `void ClearDomainEvents()` - Clear all events

## 🤝 Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Related Packages

- [Security.Claims](https://www.nuget.org/packages/Security.Claims) - Security claims and roles
- [MultiTenancy.EntityFrameworkCore](https://www.nuget.org/packages/MultiTenancy.EntityFrameworkCore) - Multi-tenant EF Core support
- [Identity.Abstractions](https://www.nuget.org/packages/Identity.Abstractions) - Authentication abstractions

## 💬 Support

- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/DomainCore/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/yourusername/DomainCore/discussions)

## How to Publish

```bash
cd  C:\desktopContents\projects\SaaS\NuGetPackages\DomainCore
.\publish-nuget.ps1 -ApiKey XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX -Bump minor -SkipPush
```
Set your key: $env:NUGET_API_KEY="..." (or pass -ApiKey)
Run minor bump + publish: publish-nuget.ps1 -Bump minor
Run major bump + publish: publish-nuget.ps1 -Bump major
Test without publishing: publish-nuget.ps1 -Bump minor -SkipPush