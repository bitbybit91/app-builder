<?php

namespace App\Core;

class Validator
{
    private array $errors = [];

    public function required(string $field, string $label): self
    {
        $value = trim($_POST[$field] ?? '');
        if ($value === '') {
            $this->errors[$field] = "{$label} is required.";
        }
        return $this;
    }

    public function email(string $field, string $label): self
    {
        $value = trim($_POST[$field] ?? '');
        if ($value !== '' && !filter_var($value, FILTER_VALIDATE_EMAIL)) {
            $this->errors[$field] = "{$label} must be a valid email address.";
        }
        return $this;
    }

    public function minLength(string $field, string $label, int $min): self
    {
        $value = trim($_POST[$field] ?? '');
        if ($value !== '' && mb_strlen($value) < $min) {
            $this->errors[$field] = "{$label} must be at least {$min} characters.";
        }
        return $this;
    }

    public function maxLength(string $field, string $label, int $max): self
    {
        $value = trim($_POST[$field] ?? '');
        if ($value !== '' && mb_strlen($value) > $max) {
            $this->errors[$field] = "{$label} must be no more than {$max} characters.";
        }
        return $this;
    }

    public function numeric(string $field, string $label): self
    {
        $value = trim($_POST[$field] ?? '');
        if ($value !== '' && !is_numeric($value)) {
            $this->errors[$field] = "{$label} must be a number.";
        }
        return $this;
    }

    public function min(string $field, string $label, float $min): self
    {
        $value = trim($_POST[$field] ?? '');
        if ($value !== '' && is_numeric($value) && (float)$value < $min) {
            $this->errors[$field] = "{$label} must be at least {$min}.";
        }
        return $this;
    }

    public function match(string $field1, string $field2, string $label): self
    {
        $val1 = $_POST[$field1] ?? '';
        $val2 = $_POST[$field2] ?? '';
        if ($val1 !== $val2) {
            $this->errors[$field2] = "{$label} do not match.";
        }
        return $this;
    }

    private const ALLOWED_TABLES = ['users', 'trades', 'trade_responses', 'messages', 'contact_messages'];
    private const ALLOWED_COLUMNS = ['username', 'email', 'id'];

    public function unique(string $field, string $label, string $table, string $column): self
    {
        if (!in_array($table, self::ALLOWED_TABLES, true) || !in_array($column, self::ALLOWED_COLUMNS, true)) {
            throw new \InvalidArgumentException('Invalid table or column for unique validation.');
        }

        $value = trim($_POST[$field] ?? '');
        if ($value !== '') {
            $stmt = Database::query(
                "SELECT COUNT(*) as cnt FROM {$table} WHERE {$column} = ?",
                [$value]
            );
            $row = $stmt->fetch();
            if ($row && $row['cnt'] > 0) {
                $this->errors[$field] = "{$label} is already taken.";
            }
        }
        return $this;
    }

    public function passes(): bool
    {
        return empty($this->errors);
    }

    public function errors(): array
    {
        return $this->errors;
    }

    public function firstError(): string
    {
        return reset($this->errors) ?: '';
    }
}
