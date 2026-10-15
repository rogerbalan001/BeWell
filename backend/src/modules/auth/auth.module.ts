import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { JwtModule } from '@nestjs/jwt';
import { MongooseModule } from '@nestjs/mongoose';
import { MedicosModule } from '../medicos/medicos.module';
import { PerfilesModule } from '../perfiles/perfiles.module';
import { AuthService } from './application/auth.service';
import { EmisorTokens, PasswordHasher } from './application/puertos';
import { UsuarioRepository } from './domain/usuario.repository';
import { Argon2PasswordHasher } from './infrastructure/argon2-password-hasher';
import { JwtEmisorTokens } from './infrastructure/jwt-emisor-tokens';
import { MongoUsuarioRepository } from './infrastructure/mongo-usuario.repository';
import { UsuarioDoc, UsuarioSchema } from './infrastructure/usuario.schema';
import { AuthController } from './interface/auth.controller';
import { JwtAuthGuard } from './interface/jwt-auth.guard';
import { RolesGuard } from './interface/roles.guard';

/** Auth & IAM. Registra JwtAuthGuard y RolesGuard como guards globales. */
@Module({
  imports: [
    JwtModule.register({}),
    MongooseModule.forFeature([{ name: UsuarioDoc.name, schema: UsuarioSchema }]),
    PerfilesModule,
    MedicosModule,
  ],
  controllers: [AuthController],
  providers: [
    AuthService,
    { provide: UsuarioRepository, useClass: MongoUsuarioRepository },
    { provide: PasswordHasher, useClass: Argon2PasswordHasher },
    { provide: EmisorTokens, useClass: JwtEmisorTokens },
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: RolesGuard },
  ],
  exports: [AuthService],
})
export class AuthModule {}
