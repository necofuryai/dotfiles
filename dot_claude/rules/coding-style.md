---
paths:
  - "**/*.{ts,tsx,js,jsx}"
---

# TypeScript/JavaScript Coding Style

## Error Handling

Use async/await with try-catch, and always preserve the original error — never throw a bare replacement:

```typescript
throw new Error('Detailed user-friendly message', { cause: error })
```

## Input Validation

Use Zod for schema-based validation:

```typescript
import { z } from 'zod'

const schema = z.object({
  email: z.string().email(),
  age: z.number().int().min(0).max(150)
})

const validated = schema.parse(input)
```
